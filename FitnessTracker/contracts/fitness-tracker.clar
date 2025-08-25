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

(define-public (set-fitness-goal (goal-type (string-ascii 20)) (target-value uint) (target-blocks uint))
  (let
    (
      (goal-id (+ (get-user-goal-count tx-sender) u1))
      (target-date (+ block-height target-blocks))
    )
    (asserts! (> target-value u0) ERR_INVALID_GOAL)
    (asserts! (> target-blocks u144) ERR_INVALID_GOAL) ;; At least 1 day
    
    (map-set fitness-goals
      { user: tx-sender, goal-id: goal-id }
      {
        goal-type: goal-type,
        target-value: target-value,
        current-value: u0,
        target-date: target-date,
        created-block: block-height,
        achieved: false,
        reward-claimed: false
      }
    )
    (ok goal-id)
  )
)

(define-public (update-goal-progress (goal-id uint) (current-value uint))
  (let
    (
      (goal (unwrap! (map-get? fitness-goals { user: tx-sender, goal-id: goal-id }) ERR_GOAL_NOT_FOUND))
      (goal-achieved (>= current-value (get target-value goal)))
    )
    (asserts! (not (get achieved goal)) ERR_GOAL_ALREADY_ACHIEVED)
    (asserts! (< block-height (get target-date goal)) ERR_INVALID_GOAL)
    
    (map-set fitness-goals
      { user: tx-sender, goal-id: goal-id }
      (merge goal {
        current-value: current-value,
        achieved: goal-achieved
      })
    )
    
    (if goal-achieved
      (begin
        (var-set total-goals-achieved (+ (var-get total-goals-achieved) u1))
        (ok { achieved: true, reward-available: true })
      )
      (ok { achieved: false, reward-available: false })
    )
  )
)

(define-public (claim-goal-reward (goal-id uint))
  (let
    (
      (goal (unwrap! (map-get? fitness-goals { user: tx-sender, goal-id: goal-id }) ERR_GOAL_NOT_FOUND))
    )
    (asserts! (get achieved goal) ERR_UNAUTHORIZED)
    (asserts! (not (get reward-claimed goal)) ERR_GOAL_ALREADY_ACHIEVED)
    
    (map-set fitness-goals
      { user: tx-sender, goal-id: goal-id }
      (merge goal { reward-claimed: true })
    )
    
    (try! (as-contract (stx-transfer? GOAL_REWARD tx-sender tx-sender)))
    (ok GOAL_REWARD)
  )
)

(define-read-only (get-user-metrics (user principal))
  (map-get? user-metrics { user: user })
)

(define-read-only (get-fitness-goal (user principal) (goal-id uint))
  (map-get? fitness-goals { user: user, goal-id: goal-id })
)

(define-read-only (get-workout-session (user principal) (session-id uint))
  (map-get? workout-sessions { user: user, session-id: session-id })
)

(define-read-only (get-daily-metrics (user principal) (day uint))
  (map-get? daily-metrics { user: user, day: day })
)

(define-read-only (calculate-bmi (user principal))
  (match (map-get? user-metrics { user: user })
    user-data 
      (let
        (
          (weight-kg (get weight-kg user-data))
          (height-m (/ (get height-cm user-data) u100))
          (bmi (/ (* weight-kg u10000) (* height-m height-m)))
        )
        (some bmi)
      )
    none
  )
)

(define-read-only (get-user-goal-count (user principal))
  (fold count-user-goals (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) u0)
)

(define-private (count-user-goals (goal-id uint) (count uint))
  (if (is-some (map-get? fitness-goals { user: tx-sender, goal-id: goal-id }))
    (+ count u1)
    count
  )
)

(define-read-only (get-total-users)
  (var-get total-users)
)

(define-read-only (get-total-goals-achieved)
  (var-get total-goals-achieved)
)