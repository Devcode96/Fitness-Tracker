;; Fitness Tracker - Comprehensive fitness metrics and goal tracking
;; Users track multiple fitness metrics and achieve personal goals

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_INVALID_METRIC (err u401))
(define-constant ERR_GOAL_NOT_FOUND (err u402))
(define-constant ERR_GOAL_ALREADY_ACHIEVED (err u403))
(define-constant ERR_INVALID_GOAL (err u404))

(define-constant GOAL_REWARD u200000) ;; 0.2 STX per achieved goal

(define-data-var total-users uint u0)
(define-data-var total-goals-achieved uint u0)

(define-map user-metrics
  { user: principal }
  {
    weight-kg: uint,
    height-cm: uint,
    body-fat-percent: uint,
    muscle-mass-kg: uint,
    last-updated: uint,
    total-workouts: uint,
    total-distance-km: uint,
    total-calories-burned: uint
  }
)

(define-map fitness-goals
  { user: principal, goal-id: uint }
  {
    goal-type: (string-ascii 20),
    target-value: uint,
    current-value: uint,
    target-date: uint,
    created-block: uint,
    achieved: bool,
    reward-claimed: bool
  }
)

(define-map daily-metrics
  { user: principal, day: uint }
  {
    steps: uint,
    calories-burned: uint,
    active-minutes: uint,
    water-intake-ml: uint,
    sleep-hours: uint,
    workout-sessions: uint
  }
)

(define-map workout-sessions
  { user: principal, session-id: uint }
  {
    workout-type: (string-ascii 30),
    duration-minutes: uint,
    calories-burned: uint,
    distance-km: uint,
    avg-heart-rate: uint,
    session-date: uint
  }
)

(define-data-var user-session-counters (list 1000 { user: principal, count: uint }) (list))