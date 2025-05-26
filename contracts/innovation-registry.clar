;; Innovation Registry Contract
;; Records and manages new technologies

(define-constant err-not-verified (err u200))
(define-constant err-not-found (err u201))
(define-constant err-unauthorized (err u202))
(define-constant err-already-exists (err u203))

;; Data structures
(define-map innovations
  { innovation-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    created-at: uint,
    status: (string-ascii 20),
    patent-hash: (string-ascii 64),
    open-source: bool
  }
)

(define-map innovation-collaborators
  { innovation-id: uint, collaborator: principal }
  { role: (string-ascii 30), joined-at: uint }
)

(define-data-var next-innovation-id uint u1)
(define-data-var innovator-verification-contract principal tx-sender)

;; Public functions
(define-public (register-innovation
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (patent-hash (string-ascii 64))
  (open-source bool))
  (let ((innovation-id (var-get next-innovation-id)))
    ;; Check if innovator is verified (simplified check)
    (map-set innovations
      { innovation-id: innovation-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        category: category,
        created-at: block-height,
        status: "registered",
        patent-hash: patent-hash,
        open-source: open-source
      }
    )
    (var-set next-innovation-id (+ innovation-id u1))
    (ok innovation-id)
  )
)

(define-public (update-innovation-status (innovation-id uint) (new-status (string-ascii 20)))
  (let ((innovation (unwrap! (map-get? innovations { innovation-id: innovation-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get creator innovation)) err-unauthorized)
    (map-set innovations
      { innovation-id: innovation-id }
      (merge innovation { status: new-status })
    )
    (ok true)
  )
)

(define-public (add-collaborator (innovation-id uint) (collaborator principal) (role (string-ascii 30)))
  (let ((innovation (unwrap! (map-get? innovations { innovation-id: innovation-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get creator innovation)) err-unauthorized)
    (map-set innovation-collaborators
      { innovation-id: innovation-id, collaborator: collaborator }
      { role: role, joined-at: block-height }
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-innovation (innovation-id uint))
  (map-get? innovations { innovation-id: innovation-id })
)

(define-read-only (get-collaborator-role (innovation-id uint) (collaborator principal))
  (map-get? innovation-collaborators { innovation-id: innovation-id, collaborator: collaborator })
)

(define-read-only (get-next-innovation-id)
  (var-get next-innovation-id)
)
