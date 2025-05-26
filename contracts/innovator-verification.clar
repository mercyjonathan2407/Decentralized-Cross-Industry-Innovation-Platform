;; Innovator Verification Contract
;; Validates and manages technology creators

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-verified (err u102))
(define-constant err-unauthorized (err u103))

;; Data structures
(define-map innovators
  { innovator: principal }
  {
    verified: bool,
    reputation-score: uint,
    specialization: (string-ascii 50),
    verification-date: uint,
    verifier: principal
  }
)

(define-map verification-requests
  { request-id: uint }
  {
    innovator: principal,
    submitted-at: uint,
    status: (string-ascii 20),
    documents-hash: (string-ascii 64)
  }
)

(define-data-var next-request-id uint u1)

;; Public functions
(define-public (submit-verification-request (specialization (string-ascii 50)) (documents-hash (string-ascii 64)))
  (let ((request-id (var-get next-request-id)))
    (map-set verification-requests
      { request-id: request-id }
      {
        innovator: tx-sender,
        submitted-at: block-height,
        status: "pending",
        documents-hash: documents-hash
      }
    )
    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

(define-public (verify-innovator (request-id uint) (innovator principal) (specialization (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set innovators
      { innovator: innovator }
      {
        verified: true,
        reputation-score: u100,
        specialization: specialization,
        verification-date: block-height,
        verifier: tx-sender
      }
    )
    (map-set verification-requests
      { request-id: request-id }
      (merge (unwrap! (map-get? verification-requests { request-id: request-id }) err-not-found)
             { status: "approved" })
    )
    (ok true)
  )
)

(define-public (update-reputation (innovator principal) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set innovators
      { innovator: innovator }
      (merge (unwrap! (map-get? innovators { innovator: innovator }) err-not-found)
             { reputation-score: new-score })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-innovator-info (innovator principal))
  (map-get? innovators { innovator: innovator })
)

(define-read-only (is-verified (innovator principal))
  (match (map-get? innovators { innovator: innovator })
    innovator-data (get verified innovator-data)
    false
  )
)

(define-read-only (get-verification-request (request-id uint))
  (map-get? verification-requests { request-id: request-id })
)
