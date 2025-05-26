;; Collaboration Contract
;; Manages joint development projects

(define-constant err-not-found (err u300))
(define-constant err-unauthorized (err u301))
(define-constant err-invalid-status (err u302))
(define-constant err-already-member (err u303))

;; Data structures
(define-map collaborations
  { collaboration-id: uint }
  {
    innovation-id: uint,
    initiator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    status: (string-ascii 20),
    created-at: uint,
    target-completion: uint,
    funding-required: uint
  }
)

(define-map collaboration-members
  { collaboration-id: uint, member: principal }
  {
    role: (string-ascii 30),
    contribution-percentage: uint,
    joined-at: uint,
    active: bool
  }
)

(define-map collaboration-milestones
  { collaboration-id: uint, milestone-id: uint }
  {
    description: (string-ascii 200),
    target-date: uint,
    completed: bool,
    completed-by: (optional principal)
  }
)

(define-data-var next-collaboration-id uint u1)

;; Public functions
(define-public (create-collaboration
  (innovation-id uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (target-completion uint)
  (funding-required uint))
  (let ((collaboration-id (var-get next-collaboration-id)))
    (map-set collaborations
      { collaboration-id: collaboration-id }
      {
        innovation-id: innovation-id,
        initiator: tx-sender,
        title: title,
        description: description,
        status: "open",
        created-at: block-height,
        target-completion: target-completion,
        funding-required: funding-required
      }
    )
    ;; Add initiator as first member
    (map-set collaboration-members
      { collaboration-id: collaboration-id, member: tx-sender }
      {
        role: "lead",
        contribution-percentage: u50,
        joined-at: block-height,
        active: true
      }
    )
    (var-set next-collaboration-id (+ collaboration-id u1))
    (ok collaboration-id)
  )
)

(define-public (join-collaboration (collaboration-id uint) (role (string-ascii 30)) (contribution-percentage uint))
  (let ((collaboration (unwrap! (map-get? collaborations { collaboration-id: collaboration-id }) err-not-found)))
    (asserts! (is-eq (get status collaboration) "open") err-invalid-status)
    (map-set collaboration-members
      { collaboration-id: collaboration-id, member: tx-sender }
      {
        role: role,
        contribution-percentage: contribution-percentage,
        joined-at: block-height,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (add-milestone
  (collaboration-id uint)
  (milestone-id uint)
  (description (string-ascii 200))
  (target-date uint))
  (let ((collaboration (unwrap! (map-get? collaborations { collaboration-id: collaboration-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get initiator collaboration)) err-unauthorized)
    (map-set collaboration-milestones
      { collaboration-id: collaboration-id, milestone-id: milestone-id }
      {
        description: description,
        target-date: target-date,
        completed: false,
        completed-by: none
      }
    )
    (ok true)
  )
)

(define-public (complete-milestone (collaboration-id uint) (milestone-id uint))
  (let ((milestone (unwrap! (map-get? collaboration-milestones { collaboration-id: collaboration-id, milestone-id: milestone-id }) err-not-found)))
    (map-set collaboration-milestones
      { collaboration-id: collaboration-id, milestone-id: milestone-id }
      (merge milestone { completed: true, completed-by: (some tx-sender) })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-collaboration (collaboration-id uint))
  (map-get? collaborations { collaboration-id: collaboration-id })
)

(define-read-only (get-member-info (collaboration-id uint) (member principal))
  (map-get? collaboration-members { collaboration-id: collaboration-id, member: member })
)

(define-read-only (get-milestone (collaboration-id uint) (milestone-id uint))
  (map-get? collaboration-milestones { collaboration-id: collaboration-id, milestone-id: milestone-id })
)
