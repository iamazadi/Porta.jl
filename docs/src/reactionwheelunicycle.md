```@meta
Description = "How the reaction wheel unicycle works."
```

# How the Reaction Wheel Unicycle Works

## Introducing Reinforcement Learning and Feedback Control

## Natural Decision Methods

## An Optimal Adaptive Controller

## The Z-Euler Angle Is Not Observable

## Stepping Through the Implementation

In this section, we step through the implementation of the robot's controller in the order of execution. The controller is implemented in the C programming language. It runs on a STM32F401RE mictocontroller, which is clocked at 84 MHz. Here. we focus on the part of the code that runs in the main loop, which is a `while` loop in the main function of the program.

- 
The microcontroller is built around a Cortex-M4 with Floating Point Unit (FPU) core, which contains hardware extensions for debugging features. The debug extensions allow the core to be stopped either on a given instruction fetch (breakpoint), or on data access (watchpoint). When stopped, the core's internal state and the system's external state may be examined. Once examination is complete, the core and the system may be restored and program execution resumed.

The ARM Cortex-M4 with FPU core provides integrated on-chip debug support. One of the debug features is called Data Watchpoint Trigger (DWT). The DWT unit  provides a means to give the number of clock cycles. The DWT register `CYCCNT` counts the number of clock cycles. The period of a control cycle is required in the application for integrating the gyroscopic angle rates. If we count the number of clocks twice: one time before the loop begins and one time after the loop ends, then we can find the time period that it takes to complete a control loop. In the beginning, we count the number of clocks by assigning the register value to a variable called `t1`.

```c
t1 = DWT->CYCCNT;
```

- 
There are two fuse bits on the robot for configuration without flashing a program. The first one is connected to the port C of the general purpose input / output, pin 0. The fuse bit is active whenever the connected pin is grounded. The fuse bit deactivates the linear quadratic regulator by clearing the `active` field as a flag in the model structure. Even though the status of the fuse bit 0 is necessary to activate the model, it is not a sufficient condition. The user must connect the fuse bit and also push a blue push button once on the robot for activating the model. The push button is the same blue button that is found on the NUCLEOF401RE board. These two conditions are chained together for safety reasons. If the model is not active, then the robot must stop moving. Therefore, the output of the model must be set to zero as well in order to override the last action of the model. But, the speed of a direct current motor is directly proportional to the amplitude of the enable signals of the motor driver. In the peripherals of the microcontroller, two channels of Timer 2 generate the driver enable signals. If the model is not active, then the duty cycle of the Pulse Width Modulation (PWM) of each timer channel is set to zero for safety. 

```c
if (HAL_GPIO_ReadPin(GPIOC, GPIO_PIN_0) == 0)
{
  if (HAL_GPIO_ReadPin(GPIOC, GPIO_PIN_13) == 0)
  {
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
    model.active = 1;
  }
}
else
{
  model.active = 0;
  model.reactionPWM = 0.0;
  model.rollingPWM = 0.0;
  TIM2->CCR1 = 0;
  TIM2->CCR2 = 0;
}
```

- 
When the reaction wheel unicycle falls over, the roll and pitch angles of the chassis with respect to the pivot point exeed ten degrees. The geared motors produce high torques in stall mode after their failure to prevent the fall from happening. It makes sense to disable the actuators to save energy resources and reduce physical shocks to the motor gearboxes. The lower and upper bounds on the roll and pitch angles are combined using the logical or `||` operator with the episode counter so that the model stops running after the maximum number of interactions with the environment, the total steps in an episode. A fall or a certain number of interactions, whichever comes first, causes the model to deactivate. In order to make the robot live longer and consume less power, three conditions must be met, or else the model is deactivated and the green light on the NUCLEOF401RE turns on to signify that the controller is no longer active. The user has four options in whenever the green LED lights up:

1. Pick the robot up and make it stand upright, before pushing the blue push button to run again.

2. Switch the power button on the chassis to condition zero, in order to power off the robot.

3. Connect to the robot WiFi network and execute the following command in the terminal for printing the logs. Print uart6 serial messages by executing: `nc 192.168.4.1 10000`

4. Activate the Porta.jl environment in a Julia REPL and run the linked script for visualizing the logs: [Unicycle](https://github.com/iamazadi/Porta.jl/blob/master/models/unicycle.jl)

The controller stops spinning and stays that way, unless one of the above are performed by the user.

```c
if (fabs(model.imu1.roll) > roll_safety_angle || fabs(model.imu1.pitch) > pitch_safety_angle || model.k > max_episode_length)
{
  model.active = 0;
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
}
```

- 
If the model is set to be active, then the controller takes one step forward. The function `stepForward` takes as argument a pointer to the model, mainly because two of its fields require persistent memory: the filter matrix `W_n` and the inverse autocorrelation matrix `P_n`. But also partly because the sensory fields among others are updated inside the function. The actual side effect of this function call is the action of the feedback policy, which changes the angular velocity of the motors.

```c
if (model.active == 1)
{
  stepForward(&model);
}
```

- 
In case the model is not active, a block of code runs instead of the `stepForward` function, in order to make sure the motors stop moving, and to update sensors for development purposes. First, the duty cycles are set to zero, both in the model struct fields and in the respective channels of Timer 2. Second, the driver inputs are all cleared to make a breaking condition according to the driver's data sheet. Third, the encoder of the reaction wheel is updated by calling the `encodeWheel` function, supplying a pointer to the encoder's instantiation and the value of the counter register `CNT` of Timer 3. Timer 3 is configured with two cannels A nd B for reading the absolute position of the wheel. What Timer 3 counts in the "encoder mode" is the angular position of the reaction wheel. Then, the `encodeWheel` function transforms the angular position to the angular velocity for the linear quadratic regulator model. The rolling wheel's encoder works in the same way, except Timer 4 is used. Next, the rate of electric current in the coils of the motors is measured by calling the `senseCurrent` function with pointers to the current sensor struct of the motors.

Finally, the Inertial Measurement Unit (IMU) is updated by calling the `updateIMU` function with the pointer to the model struct. There are two IMUs on the robot for estimating tilt at the pivot point rather than the point where the IMUs are located. The essential feature of the `updateIMU` function is the ability to calculate the roll and pitch angles using the static acceleration of gravity, discarding the dynamical part of acceleration beforehand. The quality of tilt estimation depends on three features:

1. The calculation is done for the pivot point.

2. The calculation does not consider dynamical accelerations of the robot.

3. The tilt estimation given the accelerometers is enhanced by fusing it with gyroscopic measurements.

```c
else
{
  model.reactionPWM = 0.0;
  model.rollingPWM = 0.0;
  TIM2->CCR1 = 0;
  TIM2->CCR2 = 0;
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_13, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_14, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_2, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_3, GPIO_PIN_RESET);
  encodeWheel(&model.reactionEncoder, TIM3->CNT);
  encodeWheel(&model.rollingEncoder, TIM4->CNT);
  senseCurrent(&(model.reactionCurrentSensor), &(model.rollingCurrentSensor));
  updateIMU(&model);
}
```

- 
```c
if (model.k % updatePolicyPeriod == 0)
{
  updateControlPolicy(&model);
}
```

- 
```c
t2 = DWT->CYCCNT;
diff = t2 - t1;
dt = (float)diff / CPU_CLOCK;
model.dt = dt;
```

- 
```c
log_counter++;
if (log_counter > LOG_CYCLE && HAL_GPIO_ReadPin(GPIOC, GPIO_PIN_1) == 0)
{
  transmit = 1;
}
```

- 
```c
if (transmit == 1)
{
  transmit = 0;
  log_counter = 0;

  if (log_status == 0)
  {
    sprintf(MSG,
            "AX1: %0.2f, AY1: %0.2f, AZ1: %0.2f, | AX2: %0.2f, AY2: %0.2f, AZ2: %0.2f, | roll: %0.2f, pitch: %0.2f, | encT: %0.2f, encB: %0.2f, | P0: %0.2f, P1: %0.2f, P2: %0.2f, P3: %0.2f, P4: %0.2f, dt: %0.6f\r\n",
            model.imu1.accX, model.imu1.accY, model.imu1.accZ, model.imu2.accX, model.imu2.accY, model.imu2.accZ, model.imu1.roll, model.imu1.pitch, model.reactionEncoder.radianAngle, model.rollingEncoder.radianAngle, getIndex(model.P_n, 0, 0), getIndex(model.P_n, 1, 1), getIndex(model.P_n, 2, 2), getIndex(model.P_n, 3, 3), getIndex(model.P_n, 4, 4), dt);
    log_status = 0;
  }
  HAL_UART_Transmit(&huart6, MSG, sizeof(MSG), 1000);
}
// AX1: -0.05, AY1: 0.02, AZ1: 0.99, | AX2: -0.05, AY2: 0.01, AZ2: 1.01, | roll: 0.05, pitch: -0.01, | encT: 4.21, encB: 0.81, | P0: -10.02, P1: 19.02, P2: 27.25, P3: 26.37, P4: 24.57, dt: 0.006890
// Rinse and repeat :)
```

- 
```c
/*
Identify the Q function using RLS with the given pointer to the `model`.
The algorithm is terminated when there are no further updates
to the Q function or the control policy at each step.
*/
void stepForward(LinearQuadraticRegulator *model)
```

- 
```c
int k = model->k;
```

- 
```c
x_k[0] = model->dataset.x0;
x_k[1] = model->dataset.x1;
x_k[2] = model->dataset.x2;
x_k[3] = model->dataset.x3;
x_k[4] = model->dataset.x4;
x_k[5] = model->dataset.x5;
x_k[6] = model->dataset.x6;
x_k[7] = model->dataset.x7;
x_k[8] = model->dataset.x8;
x_k[9] = model->dataset.x9;
```

- 
```c
K_j[0][0] = model->K_j.x00;
K_j[0][1] = model->K_j.x01;
K_j[0][2] = model->K_j.x02;
K_j[0][3] = model->K_j.x03;
K_j[0][4] = model->K_j.x04;
K_j[0][5] = model->K_j.x05;
K_j[0][6] = model->K_j.x06;
K_j[0][7] = model->K_j.x07;
K_j[0][8] = model->K_j.x08;
K_j[0][9] = model->K_j.x09;
K_j[1][0] = model->K_j.x10;
K_j[1][1] = model->K_j.x11;
K_j[1][2] = model->K_j.x12;
K_j[1][3] = model->K_j.x13;
K_j[1][4] = model->K_j.x14;
K_j[1][5] = model->K_j.x15;
K_j[1][6] = model->K_j.x16;
K_j[1][7] = model->K_j.x17;
K_j[1][8] = model->K_j.x18;
K_j[1][9] = model->K_j.x19;
```

- 
```c
u_k[0] = 0.0;
u_k[1] = 0.0;
```

- 
```c
// feeback policy
for (int i = 0; i < model->m; i++)
{
  for (int j = 0; j < model->n; j++)
  {
    u_k[i] += -K_j[i][j] * x_k[j];
  }
}
```

- 
```c
model->dataset.x0 = model->imu1.roll / M_PI;
model->dataset.x1 = model->imu1.roll_velocity / M_PI;
model->dataset.x2 = model->imu1.roll_acceleration / M_PI;
model->dataset.x3 = model->imu1.pitch / M_PI;
model->dataset.x4 = model->imu1.pitch_velocity / M_PI;
model->dataset.x5 = model->imu1.pitch_acceleration / M_PI;
model->dataset.x6 = model->reactionEncoder.velocity;
model->dataset.x7 = model->rollingEncoder.velocity;
model->dataset.x8 = model->reactionCurrentSensor.currentVelocity;
model->dataset.x9 = model->rollingCurrentSensor.currentVelocity;
model->dataset.x10 = u_k[0];
model->dataset.x11 = u_k[1];
```

- 
```c
model->reactionPWM += (255.0 * pulseStep) * u_k[0];
model->rollingPWM += (255.0 * pulseStep) * u_k[1];
model->reactionPWM = fmin(255.0 * 255.0, model->reactionPWM);
model->reactionPWM = fmax(-255.0 * 255.0, model->reactionPWM);
model->rollingPWM = fmin(255.0 * 255.0, model->rollingPWM);
model->rollingPWM = fmax(-255.0 * 255.0, model->rollingPWM);
TIM2->CCR1 = (int)fabs(model->rollingPWM);
TIM2->CCR2 = (int)fabs(model->reactionPWM);
if (model->reactionPWM < 0)
{
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_13, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_14, GPIO_PIN_SET);
}
else
{
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_13, GPIO_PIN_SET);
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_14, GPIO_PIN_RESET);
}
if (model->rollingPWM < 0)
{
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_2, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_3, GPIO_PIN_SET);
}
else
{
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_2, GPIO_PIN_SET);
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_3, GPIO_PIN_RESET);
}
```

- 
```c
else
{
  model->reactionPWM = 0.0;
  model->rollingPWM = 0.0;
  TIM2->CCR1 = 0;
  TIM2->CCR2 = 0;
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_13, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_14, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_2, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_3, GPIO_PIN_RESET);
}
```

- 
```c
encodeWheel(&(model->reactionEncoder), TIM3->CNT);
encodeWheel(&(model->rollingEncoder), TIM4->CNT);
senseCurrent(&(model->reactionCurrentSensor), &(model->rollingCurrentSensor));
updateIMU(model);
```

- 
```
// dataset = (xₖ, uₖ, xₖ₊₁, uₖ₊₁)
model->dataset.x12 = model->imu1.roll / M_PI;
model->dataset.x13 = model->imu1.roll_velocity / M_PI;
model->dataset.x14 = model->imu1.roll_acceleration / M_PI;
model->dataset.x15 = model->imu1.pitch / M_PI;
model->dataset.x16 = model->imu1.pitch_velocity / M_PI;
model->dataset.x17 = model->imu1.pitch_acceleration / M_PI;
model->dataset.x18 = model->reactionEncoder.velocity;
model->dataset.x19 = model->rollingEncoder.velocity;
model->dataset.x20 = model->reactionCurrentSensor.currentVelocity;
model->dataset.x21 = model->rollingCurrentSensor.currentVelocity;
```

- 
```c
x_k1[0] = model->dataset.x12;
x_k1[1] = model->dataset.x13;
x_k1[2] = model->dataset.x14;
x_k1[3] = model->dataset.x15;
x_k1[4] = model->dataset.x16;
x_k1[5] = model->dataset.x17;
x_k1[6] = model->dataset.x18;
x_k1[7] = model->dataset.x19;
x_k1[8] = model->dataset.x20;
x_k1[9] = model->dataset.x21;
```

- 
```c
u_k1[0] = 0.0;
u_k1[1] = 0.0;
```

- 
```c
for (int i = 0; i < model->m; i++)
{
  for (int j = 0; j < model->n; j++)
  {
    u_k1[i] += -K_j[i][j] * x_k1[j];
  }
}
```

- 
```c
model->dataset.x22 = u_k1[0];
model->dataset.x23 = u_k1[1];
```

- 
```c
// Compute the quadratic basis sets ϕ(zₖ), ϕ(zₖ₊₁).
z_k[0] = model->dataset.x0;
z_k[1] = model->dataset.x1;
z_k[2] = model->dataset.x2;
z_k[3] = model->dataset.x3;
z_k[4] = model->dataset.x4;
z_k[5] = model->dataset.x5;
z_k[6] = model->dataset.x6;
z_k[7] = model->dataset.x7;
z_k[8] = model->dataset.x8;
z_k[9] = model->dataset.x9;
z_k[10] = model->dataset.x10;
z_k[11] = model->dataset.x11;
```

- 
```c
z_k1[0] = model->dataset.x12;
z_k1[1] = model->dataset.x13;
z_k1[2] = model->dataset.x14;
z_k1[3] = model->dataset.x15;
z_k1[4] = model->dataset.x16;
z_k1[5] = model->dataset.x17;
z_k1[6] = model->dataset.x18;
z_k1[7] = model->dataset.x19;
z_k1[8] = model->dataset.x20;
z_k1[9] = model->dataset.x21;
z_k1[10] = model->dataset.x22;
z_k1[11] = model->dataset.x23;
```

- 
```c
for (int i = 0; i < (model->n + model->m); i++)
{
  basisset0[i] = z_k[i];
  basisset1[i] = z_k1[i];
}
```

- 
```c
// Now perform a one-step update in the parameter vector W by applying RLS to equation (S27).
// initialize z_n
for (int i = 0; i < (model->n + model->m); i++)
{
  z_n[i] = 0.0;
}
for (int i = 0; i < (model->n + model->m); i++)
{
  for (int j = 0; j < (model->n + model->m); j++)
  {
    z_n[i] += getIndex(model->P_n, i, j) * z_k[j];
  }
}
```

- 
```c
z_k1_dot_z_n = 0.0;
float buffer = 0.0;
for (int i = 0; i < (model->n + model->m); i++)
{
  buffer = z_k1[i] * z_n[i];
  if (isnanf(buffer) == 0)
  {
    z_k1_dot_z_n += buffer;
  }
}
```

- 
```c
if (fabs(model->lambda + z_k1_dot_z_n) > 0)
{
  for (int i = 0; i < (model->n + model->m); i++)
  {
    g_n[i] = (1.0 / (model->lambda + z_k1_dot_z_n)) * z_n[i];
  }
}
```

- 
```c
else
{
  for (int i = 0; i < (model->n + model->m); i++)
  {
    g_n[i] = (1.0 / model->lambda) * z_n[i];
  }
}
```

- 
```c
// αₙ = dₙ - transpose(wₙ₋₁) * xₙ
// initialize alpha_n
for (int i = 0; i < (model->n + model->m); i++)
{
  alpha_n[i] = 0.0;
}
for (int i = 0; i < (model->n + model->m); i++)
{
  for (int j = 0; j < (model->n + model->m); j++)
  {
    alpha_n[i] += getIndex(model->W_n, i, j) * (basisset1[j] - basisset0[j]); // checked manually
  }
}
```

- 
```c
for (int i = 0; i < (model->n + model->m); i++)
{
  for (int j = 0; j < (model->n + model->m); j++)
  {
    buffer = getIndex(model->W_n, i, j) + (alpha_n[i] * g_n[j]);
    if (isnanf(buffer) == 0)
    {
      setIndex(&(model->W_n), i, j, buffer); // checked manually
    }
  }
}
```

- 
```c
for (int i = 0; i < (model->n + model->m); i++)
{
  for (int j = 0; j < (model->n + model->m); j++)
  {
    buffer = (1.0 / model->lambda) * (getIndex(model->P_n, i, j) - g_n[i] * z_n[j]);
    if (isnanf(buffer) == 0)
    {
      setIndex(&(model->P_n), i, j, buffer); // checked manually
    }
  }
}
```

- 
```c
// Repeat at the next time k + 1 and continue until RLS converges and the new parameter vector Wⱼ₊₁ is found.
model->k = k + 1;
```

- 
```c
typedef struct
{
  float row0[N + M];
  float row1[N + M];
  float row2[N + M];
  float row3[N + M];
  float row4[N + M];
  float row5[N + M];
  float row6[N + M];
  float row7[N + M];
  float row8[N + M];
  float row9[N + M];
  float row10[N + M];
  float row11[N + M];
} Mat12;
```

- 
```c
float getIndex(Mat12 matrix, int i, int j)
void setIndex(Mat12 *matrix, int i, int j, float value)
```

- 
```c
void updateControlPolicy(LinearQuadraticRegulator *model)
```

- 
```c
// unpack the vector Wⱼ₊₁ into the kernel matrix
// Q(xₖ, uₖ) ≡ 0.5 * transpose([xₖ; uₖ]) * S * [xₖ; uₖ] = 0.5 * transpose([xₖ; uₖ]) * [Sₓₓ Sₓᵤ; Sᵤₓ Sᵤᵤ] * [xₖ; uₖ]
model->k = 1;
model->j = model->j + 1;
```

- 
```c
// initialize the filter matrix
// putBuffer(model->m + model->n, model->m + model->n, W_n, model->W_n);

for (int i = 0; i < model->m; i++)
{
  for (int j = 0; j < model->n; j++)
  {
    S_ux[i][j] = getIndex(model->W_n, model->n + i, j);
  }
}
```

- 
```c
for (int i = 0; i < model->m; i++)
{
  for (int j = 0; j < model->m; j++)
  {
    S_uu[i][j] = getIndex(model->W_n, model->n + i, model->n + j);
  }
}
```

- 
```c
// Perform the control update using (S24), which is uₖ = -S⁻¹ᵤᵤ * Sᵤₓ * xₖ
// uₖ = -S⁻¹ᵤᵤ * Sᵤₓ * xₖ
float determinant = S_uu[1][1] * S_uu[2][2] - S_uu[1][2] * S_uu[2][1];
// check the rank of S_uu to see if it's equal to 2 (invertible matrix)
```

- 
```c
if (fabs(determinant) > 0.0001) // greater than zero
{
  S_uu_inverse[0][0] = S_uu[1][1] / determinant;
  S_uu_inverse[0][1] = -S_uu[0][1] / determinant;
  S_uu_inverse[1][0] = -S_uu[1][0] / determinant;
  S_uu_inverse[1][1] = S_uu[0][0] / determinant;
  // initialize the gain matrix
  for (int i = 0; i < model->m; i++)
  {
    for (int j = 0; j < model->n; j++)
    {
      K_j[i][j] = 0.0;
    }
  }
  for (int i = 0; i < model->m; i++)
  {
    for (int j = 0; j < model->n; j++)
    {
      for (int k = 0; k < model->m; k++)
      {
        K_j[i][j] += S_uu_inverse[i][k] * S_ux[k][j];
      }
    }
  }
  model->K_j.x00 = K_j[0][0];
  model->K_j.x01 = K_j[0][1];
  model->K_j.x02 = K_j[0][2];
  model->K_j.x03 = K_j[0][3];
  model->K_j.x04 = K_j[0][4];
  model->K_j.x05 = K_j[0][5];
  model->K_j.x06 = K_j[0][6];
  model->K_j.x07 = K_j[0][7];
  model->K_j.x08 = K_j[0][8];
  model->K_j.x09 = K_j[0][9];
  model->K_j.x10 = K_j[1][0];
  model->K_j.x11 = K_j[1][1];
  model->K_j.x12 = K_j[1][2];
  model->K_j.x13 = K_j[1][3];
  model->K_j.x14 = K_j[1][4];
  model->K_j.x15 = K_j[1][5];
  model->K_j.x16 = K_j[1][6];
  model->K_j.x17 = K_j[1][7];
  model->K_j.x18 = K_j[1][8];
  model->K_j.x19 = K_j[1][9];
}
```

- 
```c
// instantiate a model and initialize it
LinearQuadraticRegulator model;
```

- 
```c
// Represents a Linear Quadratic Regulator (LQR) model.
typedef struct
{
  Mat12 W_n;                           // filter matrix
  Mat12 P_n;                           // inverse autocorrelation matrix
  Mat210f K_j;                         // feedback policy
  Vec24f dataset;                      // (xₖ, uₖ, xₖ₊₁, uₖ₊₁)
  int j;                               // step number
  int k;                               // time k
  int n;                               // xₖ ∈ ℝⁿ
  int m;                               // uₖ ∈ ℝᵐ
  float lambda;                        // exponential wighting factor
  float delta;                         // value used to intialize P(0)
  int active;                          // is the model controller active
  float dt;                            // period in seconds
  float reactionPWM;                   // reaction wheel's motor PWM duty cycle
  float rollingPWM;                    // rolling wheel's motor PWM duty cycle
  IMU imu1;                            // the first inertial measurement unit
  IMU imu2;                            // the second inertial measurement unit
  Encoder reactionEncoder;             // the reaction wheel encoder
  Encoder rollingEncoder;              // the rolling wheel encoder
  CurrentSensor reactionCurrentSensor; // the reaction wheel's motor current sensor
  CurrentSensor rollingCurrentSensor;  // the rolling wheel's motor current sensor
} LinearQuadraticRegulator;
```

- 
```c
void updateIMU(LinearQuadraticRegulator *model)
```

- 
```c
updateIMU1(&(model->imu1));
updateIMU2(&(model->imu2));
```

- 
```c
typedef struct
{
  int16_t accX_offset;
  int16_t accY_offset;
  int16_t accZ_offset;
  float accX_scale;
  float accY_scale;
  float accZ_scale;
  int16_t gyrX_offset;
  int16_t gyrY_offset;
  int16_t gyrZ_offset;
  float gyrX_scale;
  float gyrY_scale;
  float gyrZ_scale;
  int16_t rawAccX;
  int16_t rawAccY;
  int16_t rawAccZ;
  int16_t rawGyrX;
  int16_t rawGyrY;
  int16_t rawGyrZ;
  float accX;
  float accY;
  float accZ;
  float gyrX;
  float gyrY;
  float gyrZ;
  float roll;
  float pitch;
  float yaw;
  float roll_velocity;
  float pitch_velocity;
  float yaw_velocity;
  float roll_acceleration;
  float pitch_acceleration;
  float yaw_acceleration;
} IMU;
```

- 
```c
R1[0] = model->imu1.accX;
R1[1] = model->imu1.accY;
R1[2] = model->imu1.accZ;
R2[0] = model->imu2.accX;
R2[1] = model->imu2.accY;
R2[2] = model->imu2.accZ;
```

- 
```c
_R1[0] = 0.0;
_R1[1] = 0.0;
_R1[2] = 0.0;
_R2[0] = 0.0;
_R2[1] = 0.0;
_R2[2] = 0.0;
for (int i = 0; i < 3; i++)
{
  for (int j = 0; j < 3; j++)
  {
    _R1[i] += B_A1_R[i][j] * R1[j];
    _R2[i] += B_A2_R[i][j] * R2[j];
  }
}
```

- 
```c
for (int i = 0; i < 3; i++)
{
  Matrix[i][0] = _R1[i];
  Matrix[i][1] = _R2[i];
}
```

- 
```c
for (int i = 0; i < 3; i++)
{
  for (int j = 0; j < 4; j++)
  {
    Q[i][j] = 0.0;
    for (int k = 0; k < 2; k++)
    {
      Q[i][j] += Matrix[i][k] * X[k][j];
    }
  }
}
```

- 
```c
g[0] = Q[0][0];
g[1] = Q[1][0];
g[2] = Q[2][0];
```

- 
```c
beta = atan2(-g[0], sqrt(pow(g[1], 2) + pow(g[2], 2)));
```

- 
```c
gamma1 = atan2(g[1], g[2]);
```

- 
```c
G1[0] = model->imu1.gyrX;
G1[1] = model->imu1.gyrY;
G1[2] = model->imu1.gyrZ;
G2[0] = model->imu2.gyrX;
G2[1] = model->imu2.gyrY;
G2[2] = model->imu2.gyrZ;
```

- 
```c
_G1[0] = 0.0;
_G1[1] = 0.0;
_G1[2] = 0.0;
_G2[0] = 0.0;
_G2[1] = 0.0;
_G2[2] = 0.0;
for (int i = 0; i < 3; i++)
{
  for (int j = 0; j < 3; j++)
  {
    _G1[i] += B_A1_R[i][j] * G1[j];
    _G2[i] += B_A2_R[i][j] * G2[j];
  }
}
```

- 
```c
for (int i = 0; i < 3; i++)
{
  r[i] = (_G1[i] + _G2[i]) / 2.0;
}
```

- 
```
E[0][0] = 0.0;
E[0][1] = sin(gamma1) / cos(beta);
E[0][2] = cos(gamma1) / cos(beta);
E[1][0] = 0.0;
E[1][1] = cos(gamma1);
E[1][2] = -sin(gamma1);
E[2][0] = 1.0;
E[2][1] = sin(gamma1) * tan(beta);
E[2][2] = cos(gamma1) * tan(beta);
```

- 
```c
r_dot[0] = 0.0;
r_dot[1] = 0.0;
r_dot[2] = 0.0;
for (int i = 0; i < 3; i++)
{
  for (int j = 0; j < 3; j++)
  {
    r_dot[i] += E[i][j] * r[j];
    r_dot[i] += E[i][j] * r[j];
    r_dot[i] += E[i][j] * r[j];
    r_dot[i] += E[i][j] * r[j];
  }
}
```

- 
```c
fused_beta = kappa1 * beta + (1.0 - kappa1) * (fused_beta + model->dt * (r_dot[1] / 180.0 * M_PI));
```

- 
```c
fused_gamma = kappa2 * gamma1 + (1.0 - kappa2) * (fused_gamma + model->dt * (r_dot[2] / 180.0 * M_PI));
```

- 
```c
float _roll = fused_beta;
float _pitch = -fused_gamma;
```

- 
```c
float _roll_velocity = ((r_dot[1] / 180.0 * M_PI) + (_roll - model->imu1.roll) / model->dt) / 2.0;
float _pitch_velocity = ((-r_dot[2] / 180.0 * M_PI) + (_pitch - model->imu1.pitch) / model->dt) / 2.0;
```

- 
```c
model->imu1.roll_acceleration = _roll_velocity - model->imu1.roll_velocity;
model->imu1.pitch_acceleration = _pitch_velocity - model->imu1.pitch_velocity;
```

- 
```c
model->imu1.roll_velocity = _roll_velocity;
model->imu1.pitch_velocity = _pitch_velocity;
model->imu1.roll = _roll;
model->imu1.pitch = _pitch;
```

- 
```c
typedef struct
{
  int pulse_per_revolution; // the number of pulses per revolution
  int value;                // the counter
  float radianAngle;        // the angle in radian
  float angle;              // the absolute angle
  float velocity;           // the angular velocity
  float acceleration;       // the angular acceleration
} Encoder;
```

- 
```c
void encodeWheel(Encoder *encoder, int newValue)
```

- 
```c
encoder->value = newValue;
encoder->radianAngle = (float)(encoder->value % encoder->pulse_per_revolution) / (float)encoder->pulse_per_revolution * 2.0 * M_PI;
```

- 
```c
float angle = sin(encoder->radianAngle);
```

- 
```c
float velocity = angle - encoder->angle;
float acceleration = velocity - encoder->velocity;
```

- 
```c
encoder->angle = angle;
encoder->velocity = velocity;
encoder->acceleration = acceleration;
```

- 
```c
typedef struct
{
  float currentScale;
  int current0;
  int current1;
  float currentVelocity;
} CurrentSensor;
```

- 
```c
void senseCurrent(CurrentSensor *reactionCurrentSensor, CurrentSensor *rollingCurrentSensor)
```

- 
```c
// Start ADC Conversion in DMA Mode (Periodically Every 1ms)
HAL_ADC_Start_DMA(&hadc1, AD_RES_BUFFER, 2);
```

- 
```c
reactionCurrentSensor->current1 = reactionCurrentSensor->current0;
rollingCurrentSensor->current1 = rollingCurrentSensor->current0;
```

- 
```c
reactionCurrentSensor->current0 = (AD_RES_BUFFER[0] << 4);
rollingCurrentSensor->current0 = (AD_RES_BUFFER[1] << 4);
```

- 
```c
reactionCurrentSensor->currentVelocity = (float)(reactionCurrentSensor->current0 - reactionCurrentSensor->current1) / reactionCurrentSensor->currentScale;
rollingCurrentSensor->currentVelocity = (float)(rollingCurrentSensor->current0 - rollingCurrentSensor->current1) / rollingCurrentSensor->currentScale;
```

- 
```c
void updateIMU1(IMU *sensor) // GY-25 I2C
```

- 
```c
do
{
  HAL_I2C_Master_Transmit(&hi2c1, (uint16_t)SLAVE_ADDRESS, (uint8_t *)&transferRequest, 1, 10);
  while (HAL_I2C_GetState(&hi2c1) != HAL_I2C_STATE_READY)
    ;
} while (HAL_I2C_GetError(&hi2c1) == HAL_I2C_ERROR_AF);
```

- 
```c
do
{
  HAL_I2C_Master_Receive(&hi2c1, (uint16_t)SLAVE_ADDRESS, (uint8_t *)raw_data, 12, 10);
  while (HAL_I2C_GetState(&hi2c1) != HAL_I2C_STATE_READY)
    ;
  sensor->rawAccX = (raw_data[0] << 8) | raw_data[1];
  sensor->rawAccY = (raw_data[2] << 8) | raw_data[3];
  sensor->rawAccZ = (raw_data[4] << 8) | raw_data[5];
  sensor->rawGyrX = (raw_data[6] << 8) | raw_data[7];
  sensor->rawGyrY = (raw_data[8] << 8) | raw_data[9];
  sensor->rawGyrZ = (raw_data[10] << 8) | raw_data[11];
  sensor->accX = sensor->accX_scale * (sensor->rawAccX - sensor->accX_offset);
  sensor->accY = sensor->accY_scale * (sensor->rawAccY - sensor->accY_offset);
  sensor->accZ = sensor->accZ_scale * (sensor->rawAccZ - sensor->accZ_offset);
  sensor->gyrX = sensor->gyrX_scale * (sensor->rawGyrX - sensor->gyrX_offset);
  sensor->gyrY = sensor->gyrY_scale * (sensor->rawGyrY - sensor->gyrY_offset);
  sensor->gyrZ = sensor->gyrZ_scale * (sensor->rawGyrZ - sensor->gyrZ_offset);
} while (HAL_I2C_GetError(&hi2c1) == HAL_I2C_ERROR_AF);
```

- 
```c
void updateIMU2(IMU *sensor) // GY-95 USART
```

- 
```c
if (uart_receive_ok == 1)
```

- 
```c
if (UART1_rxBuffer[0] == UART1_txBuffer[0] && UART1_rxBuffer[1] == UART1_txBuffer[1] && UART1_rxBuffer[2] == UART1_txBuffer[2] && UART1_rxBuffer[3] == UART1_txBuffer[3])
```

- 
```c
sensor->rawAccX = (UART1_rxBuffer[5] << 8) | UART1_rxBuffer[4];
sensor->rawAccY = (UART1_rxBuffer[7] << 8) | UART1_rxBuffer[6];
sensor->rawAccZ = (UART1_rxBuffer[9] << 8) | UART1_rxBuffer[8];
sensor->rawGyrX = (UART1_rxBuffer[11] << 8) | UART1_rxBuffer[10];
sensor->rawGyrY = (UART1_rxBuffer[13] << 8) | UART1_rxBuffer[12];
sensor->rawGyrZ = (UART1_rxBuffer[15] << 8) | UART1_rxBuffer[14];
```

- 
```c
sensor->accX = sensor->accX_scale * (sensor->rawAccX - sensor->accX_offset);
sensor->accY = sensor->accY_scale * (sensor->rawAccY - sensor->accY_offset);
sensor->accZ = sensor->accZ_scale * (sensor->rawAccZ - sensor->accZ_offset);
sensor->gyrX = sensor->gyrX_scale * (sensor->rawGyrX - sensor->gyrX_offset);
sensor->gyrY = sensor->gyrY_scale * (sensor->rawGyrY - sensor->gyrY_offset);
sensor->gyrZ = sensor->gyrZ_scale * (sensor->rawGyrZ - sensor->gyrZ_offset);
```

- 
```c
float dummyx = cos(sensorAngle) * sensor->accX - sin(sensorAngle) * sensor->accY;
float dummyy = sin(sensorAngle) * sensor->accX + cos(sensorAngle) * sensor->accY;
sensor->accX = -dummyy;
sensor->accY = dummyx;
dummyx = cos(sensorAngle) * sensor->gyrX - sin(sensorAngle) * sensor->gyrY;
dummyy = sin(sensorAngle) * sensor->gyrX + cos(sensorAngle) * sensor->gyrY;
sensor->gyrX = -dummyy;
sensor->gyrY = dummyx;
```

- 
```c
uart_receive_ok = 0;
```

- 
```c
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
  if (uart_receive_ok == 0 && huart->Instance == USART1)
  {
    uart_receive_ok = 1;
  }
}
```

- 
```c
// Initialize the randomizer using the current timestamp as a seed
// (The time() function is provided by the <time.h> header file)
// srand(time(NULL));
void initialize(LinearQuadraticRegulator *model)
```

- 
```c
model->j = 1;
model->k = 1;
model->n = dim_n;
model->m = dim_m;
model->lambda = 0.99;
model->delta = 0.01;
model->active = 0;
model->dt = 0.0;
```

- 
```c
for (int i = 0; i < (model->n + model->n); i++)
{
  for (int j = 0; j < (model->n + model->n); j++)
  {
    setIndex(&(model->W_n), i, j, (float)(rand() % 100) / 100.0);
    if (i == j)
    {
      setIndex(&(model->P_n), i, j, 1.0);
    }
    else
    {
      setIndex(&(model->P_n), i, j, 0.0);
    }
  }
}
```

- 
```c
model->K_j.x00 = (float)(rand() % 100) / 100.0;
model->K_j.x01 = (float)(rand() % 100) / 100.0;
model->K_j.x02 = (float)(rand() % 100) / 100.0;
model->K_j.x03 = (float)(rand() % 100) / 100.0;
model->K_j.x04 = (float)(rand() % 100) / 100.0;
model->K_j.x05 = (float)(rand() % 100) / 100.0;
model->K_j.x06 = (float)(rand() % 100) / 100.0;
model->K_j.x07 = (float)(rand() % 100) / 100.0;
model->K_j.x08 = (float)(rand() % 100) / 100.0;
model->K_j.x09 = (float)(rand() % 100) / 100.0;
model->K_j.x10 = (float)(rand() % 100) / 100.0;
model->K_j.x11 = (float)(rand() % 100) / 100.0;
model->K_j.x12 = (float)(rand() % 100) / 100.0;
model->K_j.x13 = (float)(rand() % 100) / 100.0;
model->K_j.x14 = (float)(rand() % 100) / 100.0;
model->K_j.x15 = (float)(rand() % 100) / 100.0;
model->K_j.x16 = (float)(rand() % 100) / 100.0;
model->K_j.x17 = (float)(rand() % 100) / 100.0;
model->K_j.x18 = (float)(rand() % 100) / 100.0;
model->K_j.x19 = (float)(rand() % 100) / 100.0;
```

- 
```c
model->dataset.x0 = 0.0;
model->dataset.x1 = 0.0;
model->dataset.x2 = 0.0;
model->dataset.x3 = 0.0;
model->dataset.x4 = 0.0;
model->dataset.x5 = 0.0;
model->dataset.x6 = 0.0;
model->dataset.x7 = 0.0;
model->dataset.x8 = 0.0;
model->dataset.x9 = 0.0;
model->dataset.x10 = 0.0;
model->dataset.x11 = 0.0;
model->dataset.x12 = 0.0;
model->dataset.x13 = 0.0;
model->dataset.x14 = 0.0;
model->dataset.x15 = 0.0;
model->dataset.x16 = 0.0;
model->dataset.x17 = 0.0;
model->dataset.x18 = 0.0;
model->dataset.x19 = 0.0;
model->dataset.x20 = 0.0;
model->dataset.x21 = 0.0;
model->dataset.x22 = 0.0;
model->dataset.x23 = 0.0;
```

- 
```c
// scale : 1 / 2048
IMU imu1 = {-24, -60, 27, 0.000488281, 0.000488281, 0.000488281, 0, 0, 0, 0.017444444, 0.017444444, 0.017444444, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
IMU imu2 = {75, -25, -18, 0.000488281, 0.000488281, 0.000488281, 0, 0, 0, 0.017444444, 0.017444444, 0.017444444, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
```

- 
```c
Encoder reactionEncoder = {1736, 0, 0, 0, 0, 0};
Encoder rollingEncoder = {3020, 0, 0, 0, 0, 0};
```

- 
```c
CurrentSensor reactionCurrentSensor = {32000.0, 0, 0, 0};
CurrentSensor rollingCurrentSensor = {32000.0, 0, 0, 0};
```

- 
```c
model->imu1 = imu1;
model->imu2 = imu2;
model->reactionEncoder = reactionEncoder;
model->rollingEncoder = rollingEncoder;
model->reactionCurrentSensor = reactionCurrentSensor;
model->rollingCurrentSensor = rollingCurrentSensor;
model->reactionPWM = 0.0;
model->rollingPWM = 0.0;
```

## The Convergence of Selected Algebraic Riccati Equation Solution Parameters

## The Controllability of the Z-Euler Angle

## Nonholonomic Motion Planning

## Steering Using Sinusoids

## Steering Second-Order Canonical Systems

## Attitude Control of A Space Platform / Manipulator System Using Internal Motion

## Porta

## Fiber Optic Gyroscopes

## Resources

1. Yohanes Daud, Abdullah Al Mamun and Jian-Xin Xu, *Dynamic modeling and characteristics analysis of lateral-pendulum unicycle robot*, Robotica (2017) volume 35, pp. 537–568. Cambridge University Press 2015, doi: 10.1017/S0263574715000703.

2. Sebastian Trimpe and Raffaello D’Andrea, *Accelerometer-based Tilt Estimation of a Rigid Body with only Rotational Degrees of Freedom*, 2010 IEEE International Conference on Robotics and Automation, Anchorage Convention District, May 3-8, 2010, Anchorage, Alaska, USA.

3. K. G. Vamvoudakis, D. Vrabie and F. L. Lewis, "Online adaptive learning of optimal control solutions using integral reinforcement learning," 2011 IEEE Symposium on Adaptive Dynamic Programming and Reinforcement Learning (ADPRL), Paris, France, 2011, pp. 250-257, doi: 10.1109/ADPRL.2011.5967359.

4. Y. Engel, S. Mannor, and R. Meir, “The kernel recursive least-squares algorithm,” IEEE Transactions on Signal Processing, vol. 52, no. 8, pp. 2275–2285, 2004.

5. C. Fernandes, L. Gurvits and Z. X. Li, "Attitude control of space platform/manipulator system using internal motion," Proceedings 1992 IEEE International Conference on Robotics and Automation, Nice, France, 1992, pp. 893-898 vol.1, doi: 10.1109/ROBOT.1992.220183.

6. G. C. Walsh and S. S. Sastry, "On reorienting linked rigid bodies using internal motions," in IEEE Transactions on Robotics and Automation, vol. 11, no. 1, pp. 139-146, Feb. 1995, doi: 10.1109/70.345946.

7. Hayes, Monson H. (1996). "9.4: Recursive Least Squares". Statistical Digital Signal Processing and Modeling. Wiley. p. 541. ISBN 0-471-59431-8.

8. Richard M. Murray, Zexiang Li, and S. Shankar Sastry, *A Mathematical Introduction to Robotic Manipulation*, CRC-Press, March 22, 1994, ISBN 9780849379819, 0849379814.