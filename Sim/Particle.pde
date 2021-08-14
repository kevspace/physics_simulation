class Particle {
	//*****************CONSTANTS**************************
	final static int ON = 1;
	final static int OFF = -1;
	//****************************************************

	//vars
	PVector pos = new PVector(0, 0); //position
	PVector vel = new PVector(0, 0); //velocity
	PVector posCorrect = new PVector(0, 0); //future position used in collision calculations
	PVector futureVel = new PVector(0, 0); //future velocity used in collision calculations
	PVector acc = new PVector(0, 0); //acceleration
	color c;
	int collisionState = OFF;
	int state = ON;

	Particle() {
		this.c = colors[(int) random(0, 6)];
	}

	Particle(float xpos, float ypos, float xvel, float yvel, int colorIndex) {
		this();
		pos.set(xpos, ypos);
		vel.set(xvel, yvel);
		c = colors[colorIndex % 6];
	}

	PVector calculateForces() {
		PVector netForce = new PVector(0.0, 0.0);
		PVector force = new PVector(0.0, 0.0);

		float d = 0;
		for (Particle particle : particles) {
			if (particle != this) {
				if (particle.state == ON) {
					force = PVector.sub(particle.pos, this.pos);
					d = force.mag();
					/*
					if (d <= 20) {
						System.out.println("Particles occupied same location! Quitting program.");
						System.exit(1);
					}
					*/
					d = constrain(d, 32.0, 1281.0);
					force.normalize();
					float strength = (GRAVITATIONAL_CONSTANT * mass * mass) / (d * d);
					force.mult(strength);
					netForce.add(force);
				}
			}
		}

		/*
		for (Attractor attractor : attractors) {
			force = PVector.sub(attractor.pos, this.pos);
			d = force.mag();
			if (d <= 66) {
				System.out.println("Particles occupied same location! Quitting program.");
				System.exit(1);
			}
			force.normalize();
			float strength = (GRAVITATIONAL_CONSTANT * mass * attractor.mass) / (d * d);
			force.mult(strength);
			netForce.add(force);
		}
		*/

		return netForce;
	}

	void calculateAcc() {
		PVector f = PVector.div(calculateForces(), mass);
		float temp = constrain(f.mag(), 0.0, 1.0);
		(f.normalize()).mult(temp);
		acc.add(f);
	}

	void update() {
		if (state == ON) {
			calculateAcc();
			vel.add(acc);
			float temp = constrain(vel.mag(), 0.0, 4.0);
			(vel.normalize()).mult(temp);
			acc.mult(0);
		}
	}

	void display1() {
		if (state == ON) {
			if (container > 0) {
				//when encountering canvas edge
				if (pos.x > 984 || pos.x < 16) vel.x = -vel.x;
				if (pos.y < 16 || pos.y > 784) vel.y = -vel.y;
				if (pos.x > 984) pos.x = 984;
				if (pos.x < 16) pos.x = 16;
				if (pos.y < 16) pos.y = 16;
				if (pos.y > 784) pos.y = 784;
			} else {
				if (pos.x > 1064 || pos.x < -64 || pos.y < -64 || pos.y > 864) {
					state = OFF;
					existingParticles--;
				}
			}
		}
	}

	void display2() {
		if (state == ON) {
			//correct positions during collisoins is necessary
			for (Particle particle : particles) {
				if (particle.state == ON) {
					if (this != particle) {
						PVector distVec = PVector.sub(particle.pos, this.pos);
						float distVecMag = distVec.mag();
						float minDist = 32;
						if (distVecMag <= minDist) {
							this.collisionState = ON;
							particle.collisionState = ON;
							//if particles are too close, move them apart
							float distCorrection = (minDist - distVecMag) / 2.0;
							PVector d = distVec.copy();
							PVector correctionVec = d.normalize().mult(distCorrection);
							posCorrect.add(correctionVec);
						}
					}
				}
			}
		}
	}

	void display3() {
		if (collisionState == ON) {
			for (Particle particle : particles) {
				if (particle.state == ON) {
					if (this != particle) {
						PVector distVec = PVector.sub(particle.pos, this.pos);
						float distVecMag = distVec.mag();
						if (distVecMag <= 32.001) {
							//calculate normal and tangent vectors at collision point
							PVector collisionPoint = new PVector((this.pos.x + particle.pos.x) / 2, (this.pos.y + particle.pos.y) / 2);
							PVector normal = PVector.sub(this.pos, collisionPoint);
							PVector tangent = normal.copy();
							tangent.rotate(-HALF_PI);

							//write velocity in terms of vectors by projection
							PVector vn = sdot(vdot(this.vel, normal) / normal.magSq(), normal);
							PVector ovn = sdot(vdot(particle.vel, normal) / normal.magSq(), normal);
							PVector vt = sdot(vdot(this.vel, tangent) / tangent.magSq(), tangent);
							vn.set(formatter(vn.x), formatter(vn.y));
							ovn.set(formatter(ovn.x), formatter(ovn.y));
							vt.set(formatter(vt.x), formatter(vt.y));

							//solve 1-D collsion problem
							float a = (elasticity * mass * (sign(ovn, normal) * ovn.mag() - sign(vn, normal) * vn.mag()) + mass * (sign(vn, normal) * vn.mag() + sign(ovn, normal) * ovn.mag())) / (2 * mass);
							PVector fvn = normal.copy();
							(fvn.normalize()).mult(a);
							fvn.set(formatter(fvn.x), formatter(fvn.y));

							//store as future velocity
							this.futureVel.set(vt.x + fvn.x, vt.y + fvn.y);
							float temp = constrain(futureVel.mag(), 0.0, 4.0);
							(futureVel.normalize()).mult(temp);
							futureVel.set(formatter(futureVel.x), formatter(futureVel.y));
						}
					}
				}
			}
		}

			/*
			for (Attractor attractor: attractors) {
				PVector d = PVector.sub(attractor.pos, this.pos);
				if (d.mag() <= FACTOR * mass / 2 + attractor.mass / 2) {
					this.vel.set(-this.vel.x, -this.vel.y);
				}
			}
			*/

		strokeWeight(1);
		stroke(c);
		fill(c);
		ellipse(pos.x, pos.y, 32, 32);
	}

	float vdot(PVector a, PVector b) {
		return a.x * b.x + a.y * b.y;
	}

	PVector sdot(float c, PVector v) {
		PVector p = new PVector(c * v.x, c * v.y);
		return p;
	}

	float sign(PVector a, PVector b) {
		if (vdot(a, b) == 0) return 0;
		return vdot(a, b) / abs(vdot(a, b));
	}

	float formatter(float f) {
		String temp = String.format("%.3f", f);
		return Float.parseFloat(temp);
	}
}
