;; title: caregiver-registry
;; version: 1.0.0
;; summary: Registers and manages caregivers with credentials and specializations
;; description: A smart contract for caregiver registration, credential verification,
;; availability management, rating tracking, and experience documentation.

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-rating (err u103))
(define-constant err-already-registered (err u104))
(define-constant err-not-verified (err u105))

;; Data Variables
(define-data-var caregiver-nonce uint u0)
(define-data-var assignment-nonce uint u0)

;; Data Maps
(define-map caregivers
  { caregiver-id: uint }
  {
    wallet: principal,
    name: (string-utf8 200),
    bio: (string-utf8 1000),
    specializations: (string-utf8 500),
    hourly-rate: uint,
    is-available: bool,
    is-verified: bool,
    background-check-date: (optional uint),
    total-hours-worked: uint,
    total-assignments: uint,
    average-rating: uint,
    rating-count: uint,
    registered-at: uint
  }
)

(define-map caregiver-by-wallet
  { wallet: principal }
  { caregiver-id: uint }
)

(define-map certifications
  { caregiver-id: uint, cert-type: (string-ascii 50) }
  {
    cert-name: (string-utf8 200),
    issuer: (string-utf8 200),
    issue-date: uint,
    expiry-date: (optional uint),
    is-verified: bool
  }
)

(define-map assignments
  { assignment-id: uint }
  {
    caregiver-id: uint,
    client: principal,
    start-block: uint,
    end-block: (optional uint),
    hours-logged: uint,
    rate-per-hour: uint,
    is-active: bool,
    is-completed: bool
  }
)

(define-map ratings
  { caregiver-id: uint, rater: principal, assignment-id: uint }
  {
    rating: uint,
    review: (optional (string-utf8 500)),
    rated-at: uint
  }
)

(define-map availability-schedule
  { caregiver-id: uint, day-of-week: uint }
  {
    is-available: bool,
    start-hour: uint,
    end-hour: uint
  }
)

(define-map emergency-contacts
  { caregiver-id: uint }
  {
    contact-name: (string-utf8 200),
    contact-phone: (string-ascii 20),
    relationship: (string-utf8 100)
  }
)

;; Public Functions

;; Register as a caregiver
(define-public (register-caregiver (name (string-utf8 200))
                                   (bio (string-utf8 1000))
                                   (specializations (string-utf8 500))
                                   (hourly-rate uint)
                                   (available bool))
  (let
    (
      (new-caregiver-id (+ (var-get caregiver-nonce) u1))
      (existing (map-get? caregiver-by-wallet { wallet: tx-sender }))
    )
    (asserts! (is-none existing) err-already-registered)
    (map-set caregivers
      { caregiver-id: new-caregiver-id }
      {
        wallet: tx-sender,
        name: name,
        bio: bio,
        specializations: specializations,
        hourly-rate: hourly-rate,
        is-available: available,
        is-verified: false,
        background-check-date: none,
        total-hours-worked: u0,
        total-assignments: u0,
        average-rating: u0,
        rating-count: u0,
        registered-at: stacks-block-height
      }
    )
    (map-set caregiver-by-wallet
      { wallet: tx-sender }
      { caregiver-id: new-caregiver-id }
    )
    (var-set caregiver-nonce new-caregiver-id)
    (ok new-caregiver-id)
  )
)

;; Update caregiver profile
(define-public (update-profile (caregiver-id uint)
                               (bio (string-utf8 1000))
                               (specializations (string-utf8 500))
                               (hourly-rate uint))
  (let
    (
      (caregiver (unwrap! (map-get? caregivers { caregiver-id: caregiver-id }) err-not-found))
    )
    (asserts! (is-eq (get wallet caregiver) tx-sender) err-unauthorized)
    (map-set caregivers
      { caregiver-id: caregiver-id }
      (merge caregiver {
        bio: bio,
        specializations: specializations,
        hourly-rate: hourly-rate
      })
    )
    (ok true)
  )
)

;; Update availability status
(define-public (update-availability (caregiver-id uint) (available bool))
  (let
    (
      (caregiver (unwrap! (map-get? caregivers { caregiver-id: caregiver-id }) err-not-found))
    )
    (asserts! (is-eq (get wallet caregiver) tx-sender) err-unauthorized)
    (map-set caregivers
      { caregiver-id: caregiver-id }
      (merge caregiver { is-available: available })
    )
    (ok true)
  )
)

;; Add certification
(define-public (add-certification (caregiver-id uint)
                                 (cert-type (string-ascii 50))
                                 (cert-name (string-utf8 200))
                                 (issuer (string-utf8 200))
                                 (issue-date uint)
                                 (expiry-date (optional uint)))
  (let
    (
      (caregiver (unwrap! (map-get? caregivers { caregiver-id: caregiver-id }) err-not-found))
    )
    (asserts! (is-eq (get wallet caregiver) tx-sender) err-unauthorized)
    (map-set certifications
      { caregiver-id: caregiver-id, cert-type: cert-type }
      {
        cert-name: cert-name,
        issuer: issuer,
        issue-date: issue-date,
        expiry-date: expiry-date,
        is-verified: false
      }
    )
    (ok true)
  )
)

;; Verify caregiver background
(define-public (verify-background (caregiver-id uint))
  (let
    (
      (caregiver (unwrap! (map-get? caregivers { caregiver-id: caregiver-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set caregivers
      { caregiver-id: caregiver-id }
      (merge caregiver {
        is-verified: true,
        background-check-date: (some stacks-block-height)
      })
    )
    (ok true)
  )
)

;; Create new assignment
(define-public (create-assignment (caregiver-id uint) (rate uint))
  (let
    (
      (caregiver (unwrap! (map-get? caregivers { caregiver-id: caregiver-id }) err-not-found))
      (new-assignment-id (+ (var-get assignment-nonce) u1))
    )
    (asserts! (get is-available caregiver) err-not-found)
    (map-set assignments
      { assignment-id: new-assignment-id }
      {
        caregiver-id: caregiver-id,
        client: tx-sender,
        start-block: stacks-block-height,
        end-block: none,
        hours-logged: u0,
        rate-per-hour: rate,
        is-active: true,
        is-completed: false
      }
    )
    (map-set caregivers
      { caregiver-id: caregiver-id }
      (merge caregiver {
        total-assignments: (+ (get total-assignments caregiver) u1)
      })
    )
    (var-set assignment-nonce new-assignment-id)
    (ok new-assignment-id)
  )
)

;; Complete assignment and log hours
(define-public (complete-assignment (assignment-id uint) (hours uint))
  (let
    (
      (assignment (unwrap! (map-get? assignments { assignment-id: assignment-id }) err-not-found))
      (caregiver (unwrap! (map-get? caregivers { caregiver-id: (get caregiver-id assignment) }) err-not-found))
    )
    (asserts! (is-eq (get client assignment) tx-sender) err-unauthorized)
    (asserts! (get is-active assignment) err-not-found)
    (map-set assignments
      { assignment-id: assignment-id }
      (merge assignment {
        end-block: (some stacks-block-height),
        hours-logged: hours,
        is-active: false,
        is-completed: true
      })
    )
    (map-set caregivers
      { caregiver-id: (get caregiver-id assignment) }
      (merge caregiver {
        total-hours-worked: (+ (get total-hours-worked caregiver) hours)
      })
    )
    (ok true)
  )
)

;; Rate a caregiver
(define-public (rate-caregiver (caregiver-id uint)
                               (assignment-id uint)
                               (rating uint)
                               (review (optional (string-utf8 500))))
  (let
    (
      (caregiver (unwrap! (map-get? caregivers { caregiver-id: caregiver-id }) err-not-found))
      (assignment (unwrap! (map-get? assignments { assignment-id: assignment-id }) err-not-found))
      (current-total (* (get average-rating caregiver) (get rating-count caregiver)))
      (new-count (+ (get rating-count caregiver) u1))
      (new-average (/ (+ current-total rating) new-count))
    )
    (asserts! (is-eq (get client assignment) tx-sender) err-unauthorized)
    (asserts! (get is-completed assignment) err-not-found)
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
    (map-set ratings
      { caregiver-id: caregiver-id, rater: tx-sender, assignment-id: assignment-id }
      {
        rating: rating,
        review: review,
        rated-at: stacks-block-height
      }
    )
    (map-set caregivers
      { caregiver-id: caregiver-id }
      (merge caregiver {
        average-rating: new-average,
        rating-count: new-count
      })
    )
    (ok true)
  )
)

;; Read-Only Functions

;; Get caregiver information
(define-read-only (get-caregiver-info (caregiver-id uint))
  (ok (map-get? caregivers { caregiver-id: caregiver-id }))
)

;; Get caregiver by wallet
(define-read-only (get-caregiver-by-wallet (wallet principal))
  (match (map-get? caregiver-by-wallet { wallet: wallet })
    record (ok (map-get? caregivers { caregiver-id: (get caregiver-id record) }))
    (err err-not-found)
  )
)

;; Get certification
(define-read-only (get-certification (caregiver-id uint) (cert-type (string-ascii 50)))
  (ok (map-get? certifications { caregiver-id: caregiver-id, cert-type: cert-type }))
)

;; Get assignment details
(define-read-only (get-assignment (assignment-id uint))
  (ok (map-get? assignments { assignment-id: assignment-id }))
)

;; Get rating
(define-read-only (get-rating (caregiver-id uint) (rater principal) (assignment-id uint))
  (ok (map-get? ratings { caregiver-id: caregiver-id, rater: rater, assignment-id: assignment-id }))
)

;; Check if caregiver is available
(define-read-only (is-caregiver-available (caregiver-id uint))
  (match (map-get? caregivers { caregiver-id: caregiver-id })
    caregiver (ok (get is-available caregiver))
    (err err-not-found)
  )
)

;; Check if caregiver is verified
(define-read-only (is-caregiver-verified (caregiver-id uint))
  (match (map-get? caregivers { caregiver-id: caregiver-id })
    caregiver (ok (get is-verified caregiver))
    (err err-not-found)
  )
)

;; Get caregiver count
(define-read-only (get-caregiver-count)
  (ok (var-get caregiver-nonce))
)

;; Get assignment count
(define-read-only (get-assignment-count)
  (ok (var-get assignment-nonce))
)
