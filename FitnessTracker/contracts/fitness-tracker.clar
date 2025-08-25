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

(define-public (initialize-user-profile (weight-kg uint) (height-cm uint))
  (let
    (
      (existing-profile (map-get? user-metrics { user: tx-sender }))
    )
    (asserts! (is-none existing-profile) ERR_UNAUTHORIZED)
    (asserts! (and (> weight-kg u30) (< weight-kg u300)) ERR_INVALID_METRIC)
    (asserts! (and (> height-cm u100) (< height-cm u250)) ERR_INVALID_METRIC)
    
    (map-set user-metrics
      { user: tx-sender }
      {
        weight-kg: weight-kg,
        height-cm: height-cm,
        body-fat-percent: u0,
        muscle-mass-kg: u0,
        last-updated: block-height,
        total-workouts: u0,
        total-distance-km: u0,
        total-calories-burned: u0
      }
    )
    
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
  )
)

(define-public (update-body-composition (weight-kg uint) (body-fat-percent uint) (muscle-mass-kg uint))
  (let
    (
      (user-data (unwrap! (map-get? user-metrics { user: tx-sender }) ERR_UNAUTHORIZED))
    )
    (asserts! (and (> weight-kg u30) (< weight-kg u300)) ERR_INVALID_METRIC)
    (asserts! (<= body-fat-percent u50) ERR_INVALID_METRIC)
    (asserts! (< muscle-mass-kg weight-kg) ERR_INVALID_METRIC)
    
    (map-set user-metrics
      { user: tx-sender }
      (merge user-data {
        weight-kg: weight-kg,
        body-fat-percent: body-fat-percent,
        muscle-mass-kg: muscle-mass-kg,
        last-updated: block-height
      })
    )
    (ok true)
  )
)

(define-public (log-workout-session 
                (workout-type (string-ascii 30)) 
                (duration-minutes uint) 
                (calories-burned uint) 
                (distance-km uint) 
                (avg-heart-rate uint))
  (let
    (
      (user-data (unwrap! (map-get? user-metrics { user: tx-sender }) ERR_UNAUTHORIZED))
      (session-id (+ (get total-workouts user-data) u1))
    )
    (asserts! (and (> duration-minutes u0) (<= duration-minutes u300)) ERR_INVALID_METRIC)
    (asserts! (<= calories-burned u2000) ERR_INVALID_METRIC)
    (asserts! (<= distance-km u100) ERR_INVALID_METRIC)
    (asserts! (and (>= avg-heart-rate u60) (<= avg-heart-rate u220)) ERR_INVALID_METRIC)
    
    (map-set workout-sessions
      { user: tx-sender, session-id: session-id }
      {
        workout-type: workout-type,
        duration-minutes: duration-minutes,
        calories-burned: calories-burned,
        distance-km: distance-km,
        avg-heart-rate: avg-heart-rate,
        session-date: block-height
      }
    )
    
    (map-set user-metrics
      { user: tx-sender }
      (merge user-data {
        total-workouts: session-id,
        total-distance-km: (+ (get total-distance-km user-data) distance-km),
        total-calories-burned: (+ (get total-calories-burned user-data) calories-burned),
        last-updated: block-height
      })
    )
    
    (ok session-id)
  )
)

(define-public (log-daily-metrics 
                (steps uint) 
                (calories-burned uint) 
                (active-minutes uint) 
                (water-intake-ml uint) 
                (sleep-hours uint))
  (let
    (
      (current-day (/ block-height u144))
    )
    (asserts! (<= steps u100000) ERR_INVALID_METRIC)
    (asserts! (<= calories-burned u5000) ERR_INVALID_METRIC)
    (asserts! (<= active-minutes u1440) ERR_INVALID_METRIC)
    (asserts! (<= water-intake-ml u5000) ERR_INVALID_METRIC)
    (asserts! (<= sleep-hours u12) ERR_INVALID_METRIC)
    
    (map-set daily-metrics
      { user: tx-sender, day: current-day }
      {
        steps: steps,
        calories-burned: calories-burned,
        active-minutes: active-minutes,
        water-intake-ml: water-intake-ml,
        sleep-hours: sleep-hours,
        workout-sessions: u0
      }
    )
    (ok true)
  )
)