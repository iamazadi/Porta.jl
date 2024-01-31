---
layout: post
title:  "How Does A Self-Balancing Robot Work Mathematically?"
---

Inspired by [The Portal, episode 20,](https://youtu.be/mg93Dm-vYc8) with the host Eric Weinstein and the guest Sir Roger Penrose.

How Does A Self-Balancing Robot Work Mathematically?

# Introduction
### Introducing the self-balance robot.
Today, we are going to talk about the way that a mono-wheel works. It is a self-balancing robot with only one wheel. But, it can keep its balance along two axes. Therefore, it is like a two-wheel balance robot when it is balancing forwards and backwards. And it is different from a two-wheel balance robot because it uses a reaction wheel in order to balance in the left and right direction.

![front](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/front.PNG)

## Origins

### What does this explain?

When the robot is turned off, try to manually balance it. Show that it has a single point of contact with the ground via the main wheel, and has two degrees of freedom.

![calibration](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/calibration.PNG)
![calibration1](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/calibration1.PNG)

### Acquiring sensory data via an IMU.

The mono-wheel computes the angular velocity of its body with respect to the ground using a gyroscope. The sensor works based on the Micro-ElectroMechanical Systems (MEMS) technology. There are micron-scale moving parts (weights on springs) inside a very tiny chip for measuring inertial forces acted on the microchip from the outside environment. The Inertial Measurement Unit (IMU) that we use for this project is depicted in the figure below.

![mpu](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/mpu.JPG)
![pcb](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/pcb.PNG)

### How hard is the task?

Try to balance a ball pen or pencil on a desktop. When the pen falls, repeat by picking it up and holding it on the tip, contacting the surface, at a point.

![pencil](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/pencil.PNG)

## Breakdown

### Modeling the main wheel’s behavior.

Modeling the motion of the robot along two different directions, we study the dynamic behavior of the robot to control it. For that reason, model a mathematical model of the robot in order to describe the robot's performance based on the applied input, which is the motor's supply voltage. 

![computation1](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation1.PNG)

In the equation number one (see the image below) omega denotes the angular velocity of the motor's axis, which is measured by the encoder, and e denotes the counter-electromotive force.

![equation1](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation1.PNG)

Whenever the motor's current changes, due to the motor's inductance, it generates a voltage in opposition to the changing current via Faraday's law. While the motor's armature is spinning in a magnetic field with constant current, the Back-ElectroMotive Force (Back-EMF) is non-zero, because the motor acts as a  generator while moving.

![encoder](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/figure1.PNG)
![emf1](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/figure2.JPG)
![emf2](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/figure3.JPG)
![emf3](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/figure4.JPG)

Controlling the robot, back-EMF is a function of the motor's rotation speed. Therefore, back-EMF is zero whenever the rotation speed is zero as well. In equation 1 the term k_tau is called the torque constant, and k_e is called the back-EMF constant. The parameters R and L denote the resistance and the inductance of the motor's coils in the armature. Since the electrical behavior of the robot is much faster than its mechanical behavior, lower time constant, the inductance property that underlies the electrodynamics of the motor's coils is negligible and so has been removed from the equations.
After removing the inductance property of the motor L, equation 1 becomes an approximation of the applied voltage in terms of the torque and velocity. In ideal motors, the constant torque k_tau and k_e are equal. But, in reality this isn’t the case and they have different values to be measured in an experimental way. In the following equations, according to the physical features of the robot, the laws of Newtonian motion are derived.
Also in this section, the method of Lagrangian mechanics is useful. In the configuration space diagrams of the robot the total mass of the robot is located at its center of mass. Equation 1 explains the relation between the motor's supply voltage and output torque: The angular speed of the output axis of the motor with respect to the motor's body is denoted by omega and equals the difference between the angular speed of the wheel and the robot's body (or motor's body) in the coordinate system of the ground.

![frontview](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/frontview.PNG)

First we investigate the mathematical model of the robot's movement in the forward/backward direction and its deviation from the vertical state. This movement is managed by the robot's main wheel and is similar to the dynamics of a two-wheel balancing robot. 

![wheel](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/figure5.JPG)

Using Newton's rules for the main wheel and the robot's body in the XZ plane we have:

![equation2](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation2.PNG)

In this figure, the mass of the robot and its main wheel are denoted by m_r and m_w, and their rotational moment of inertia are denoted by I_r and I_w, respectively. 

![robot](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/figure6.JPG)

The parameter m_r signifies the mass of all of the robot's parts excluding the main wheel and is located at the center of mass at a point.

![equation3](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation3.PNG)

The parameter I_r shows the rotational moment of inertia of all of the robot's parts, except for the main wheel about the axis through the center of mass (parallel to the axis through the main wheel). For calculating m_r and I_r, the reaction wheel is assumed to be a static part of the robot's body. The parameters m_w and I_w represent the main wheel's mass and rotational moment of inertia, respectively.

![figure7](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/figure7.JPG)

The letters H, V and H stand for Horizontal, Vertical and Friction, respectively. They represent the horizontal, vertical and friction forces.

![equation4](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation4.PNG)
![equation5](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation5.PNG)
![equation6](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation6.PNG)

By solving equations 1-6 simultaneously, We find the equations that describe the system. To extract the state equations, begin with equation 1:

![computation2](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation2.PNG)

Insert that into equation 3:

![computation3](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation3.PNG)
![computation4](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation4.PNG)

Then, substitute equation 2:

![computation5](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation5.PNG)

Then, substitute equation 4:

![computation6](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation6.PNG)

Then, divide both sides of the equation by minus r times R:

![equation7](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation7.PNG)

That is one of the state equations. Now, begin with equation 6 again, for finding the other equation.

![computation7](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation7.PNG)

Next, insert equations 4 and 5 into equation 6:

![computation8](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation8.PNG)

From equation 1 we had:

![computation9](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation9.PNG)

Therefore,

![computation10](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation10.PNG)

Looks like we need to replace the value of V. But, from using equation 7 we can write the following equation.

![computation11](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation11.PNG)

Therefore the following equation can take its final form.

![computation12](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation12.PNG)

After a rearrangement.

![computation13](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation13.PNG)

The final form of the main wheel system’s second state equation looks like this:

![equation8](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation8.PNG)

Equations 7 and 8 determine the robot's behavior in the direction of the X-axis and its deviation in rotating about the Y-axis (angle theta) in terms of the main motor's supply voltage. Next, we derive the mathematical model of the robot in deviation around the X-axis (angle phi) and the effect of the reaction wheel.

### Modeling the reaction wheel’s behavior.

![figure8](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/figure8.JPG)

In this figure, the mass of all of the robot's parts (including the body, the main wheel and the reaction wheel) is denoted by m_r and is located at a concentrated center of mass at one point. The rotational inertia of all of the parts of the robot, excluding the reaction wheel, is denoted by I_r. And the rotational inertia of the reaction wheel is identified with I_w. 

![figure9](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/figure9.JPG)

The parameter I_w is calculated about the reaction wheel's axis. And the parameter I_r is calculated about an axis parallel to the axis of the reaction wheel, but at the contact point of the main wheel with the ground (axis 2). Remember that the whole body of the robot oscillates about this axis. 

In addition to gravity, we have a thin flexible band over the circumference of the main wheel at the point of contact of the wheel and the ground. The flexible belt effectively acts as a spring that resists side-to-side motions of the robot (angle phi) and tries to keep the robot upright. The rubber part on the main wheel is used to create friction with the ground, but it's slightly wider than the wheel’s width. The force from this spring is given by the Hooke's law:

![equation9](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation9.PNG)

In equation 9, k_s denotes the spring constant constant and l denotes the length between the center of mass of the robot's body and the contact point on axis 2. The equations that govern the reaction wheel’s driver are similar to those of the main motor, as equation 10 suggests.

![equation10](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation10.PNG)
![figure10](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/figure10.JPG)

Here is the equation governing the angular motion of the reaction wheel about its axis.

![equation11](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation11.PNG)

The equation ruling the rotational motion of the entire robot about axis 2 at the point of contact of the robot with the ground:

![equation12](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation12.PNG)

In the equations above the parameters m_r and I_r are written for the whole robot, including the reaction wheel since gravity applies to every part. The parameters m_w and I_w are specifically related to the reaction wheel. Note that the rotational inertia I_r and I_w are calculated about two different axes. By solving equations 9 through 12 simultaneously, and assuming the linear approximation that sin(phi) is approximately equal to phi for small angles, the equations describing the system's state are extracted.

![computation14](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation14.PNG)
![computation15](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation15.PNG)


![equation13](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation13.PNG)

Equation 13 without the force of the spring takes a different form, which makes sense because the rubber piece on the main wheel should affect the acceleration of angle phi.

![computation16](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation16.PNG)

Also, equation 13 defines the first state equation of the reaction wheel’s controller. Next, we find the other half of the system's state equations. 

![computation17](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation17.PNG)
![computation18](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation18.PNG)
![computation19](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/computation19.PNG)

The answer appears as equation 14 after simplification, completing the second half of the system’s state equations.

Here, we extracted two different mathematical models for the motion of the robot around two perpendicular axes. Using the equations that describe these motions (equations 7 and 8 or equations 13 and 14) we can extract the system's transform matrix in that motion, or find its state space. The system's state at time-step n equals the transform of the system's state at time-step n minus one. Finally, keeping balance in two different directions is going to require two separate controllers. The controller that controls angle theta and motion along axis X commands The main motor, whereas the controller that controls angle phi commands the motor of the reaction wheel.

![equation14](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation14.PNG)


### Monitoring the controller in action.

![stateController](stateController.png)

Poke the robot from two different directions gently while the controller is active. Show that it recovers from small pushes exerted on the robot’s columns via finger tip. It can recover its orientation from small dynamic accelerations. Unlike the static acceleration of the Earth’s gravity, pushing the robot counts as a dynamic acceleration. And the robot is robust to dynamic accelerations, within the saturation limits of the reaction wheel.

![ugn3503](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/ugn3503.JPG)

The Hall effect sensors are located inside the servo motor’s housing, for measuring the angular velocity of the reaction wheel (omega). Two sensors are mounted against a stack of three magnetic disks rotating around the motor’s axis.

![graph](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/graph.png)

The sensor reading is analog and the time-series is a periodic function at constant revolutions per minute (angular velocity).

## Other Views
### Comparing with other unicycles.

We can compare the mono-wheel with various types of balance robots:
- Two-wheel balance robots
- The Murata bicycle
- The Cubli: a cube that can jump up and balance
- The Wheelbot: a jumping reaction wheel unicycle
- Honda UNI-CUB: a self balancing one-wheeled personal transporter
- Ball balance robots.


### Modeling the rubber band on the main wheel.

We studied the mathematical equations of the robot’s motion. The interesting thing about these equations is that when we model the flex joint of the inverted pendulum in the robot (see the rubber on the main wheel 🛞) equation 13 changes explicitly, but equation 14 changes implicitly via the acceleration of the reaction wheel.

![spring](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/spring.PNG)
![equation13](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation13.PNG)
![equation14](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/equation14.PNG)

### The issue of the saturation of the reaction wheel.

Talking about the limits of the reaction wheel system, one of the problems occurs whenever the reaction wheel goes into the saturation mode. The wheel saturates when it reaches max speed in terms of RPM and can no longer provide additional torque beyond current supply. As soon as the system goes into regions of the state space where the supplied toque by the reaction wheel is insufficient the robot becomes unstable and falls over its sides.

![problem](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/problem.PNG)

### A solution for the saturation problem.

Using either a motor with higher Revolutions Per Minute (RPM) with a reaction wheel that has a lower rotational inertia, or a lower RPM motor with a reaction wheel that has a higher rotational inertia should alleviate the saturation problem. The second solution is preferable because any kind of manufacturing inaccuracies in building the symmetrical reaction wheel causes the robot to become unstable at high speeds, due to unwanted high-frequency wobbling.

![reactionWheel](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/reactionWheel.PNG)
![solution](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/solution.PNG)

## Takeaway
### Why is the robot relevant today?

The mono-wheel may look like just research lab equipment. But, its most important part is a reaction wheel, which has special applications in satellites. Satellites use reaction wheels for performing small maneuvers in orbit. In addition, the robot is a great platform for designing, implementing and testing various control algorithms.

![takeaway](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/takeaway.png)

### A resource to learn more.

We recommend reading the book: “The Design and Implementation of Self-Balancing Robots” by Mohammad Mashaghi, published in 2013. For example, we found the 3D design of the robot inside the book.

![book](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/book.PNG)

## Closer
### Reinforcement learning on embedded systems.

Training a Reinforcement learning (RL) policy for balancing, by expanding the system state to include states from the past time-steps. Predicting the next state and producing motor commands running on sub-Watt computers.

![microcontroller](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/microcontroller.JPG)
![driver](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/driver.JPG)

### References 

1. The Inverted Pendulum lab experiment notes from Caltech, http://pmaweb.caltech.edu/~phy003/handout_source/Inverted_Pendulum/InvertedPendulum.pdf.
2. Mohanarajah Gajamohan, Michael Merz, et al., The Cubli: A Cube that Can Jump Up and Balance, 2012.
3. A. Rene ́ Geist, Jonathan Fiene, et al., The Wheelbot: A Jumping Reaction Wheel Unicycle, 2022.
4. Sir Roger Penrose, The Road to Reality: A Complete Guide to the Laws of the Universe, 2004.
5. Ivan Savov, No Bullshit Guide to Linear Algebra, 2017.
6. David. J., Griffiths, Introduction to Electrodynamics, 2012.
7. Mohammad Mashaghi, The Design and Implementation of Self-balancing Robots, 2013, www.nashreolum.com.
8. Stephen Boyd, EE263: Introduction to Linear Dynamical Systems, Stanford university.
9. Tom Lancaster, Stephen J. Blundell, Quantum Field Theory for the Gifted Amateur, 2014.


### Statement Video

Please click on the image below to watch the statement video!

[![statement video](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/2024-01-31-how-does-a-self-balancing-robot-work-mathematically/cover.PNG)](https://youtu.be/rBjlrpOvGok)