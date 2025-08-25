# Fitness Tracker

Comprehensive fitness metrics tracking with goal setting, progress monitoring, and STX rewards for achievements.

## Features

- Complete body composition tracking (weight, body fat, muscle mass)
- Detailed workout session logging with heart rate monitoring
- Daily activity metrics (steps, calories, sleep, water intake)
- Personal fitness goals with automatic progress tracking
- STX rewards for achieving fitness milestones
- BMI calculation and health metrics analysis

## Tracked Metrics

**Body Composition:**
- Weight (30-300 kg)
- Height (100-250 cm)
- Body fat percentage (0-50%)
- Muscle mass tracking

**Workout Sessions:**
- Exercise type and duration (1-300 minutes)
- Calories burned (up to 2,000 per session)
- Distance covered (up to 100 km)
- Average heart rate (60-220 BPM)

**Daily Activities:**
- Step count (up to 100,000)
- Active minutes (up to 1,440)
- Water intake (up to 5,000 ml)
- Sleep duration (up to 12 hours)

## How to Use

1. Initialize profile with `initialize-user-profile` (weight, height)
2. Set fitness goals using `set-fitness-goal` with target values
3. Log workouts with `log-workout-session` including all metrics
4. Update body composition with `update-body-composition`
5. Track daily activities with `log-daily-metrics`
6. Update goal progress and claim 0.2 STX rewards for achievements

## Smart Contract Functions

- `initialize-user-profile`: Create fitness profile with basic metrics
- `set-fitness-goal`: Create trackable fitness objectives
- `log-workout-session`: Record complete workout data
- `update-goal-progress`: Update progress toward goals
- `claim-goal-reward`: Collect 0.2 STX for achieved goals
- `calculate-bmi`: Get automatic BMI calculation

## Goal System

- Set custom fitness targets with deadlines
- Automatic achievement detection
- 0.2 STX reward per achieved goal
- Progress tracking with current vs target values
- Goal types: weight loss, distance, workout frequency, etc.