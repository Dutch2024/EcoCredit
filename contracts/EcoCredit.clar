;; EcoCredit - Decentralized Carbon Credit Trading and Verification Platform
(define-fungible-token carbon-credit)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-permitted (err u601))
(define-constant err-insufficient-credits (err u401))
(define-constant err-project-not-found (err u402))
(define-constant err-already-audited (err u403))
(define-constant err-audit-period-closed (err u404))
(define-constant err-audit-still-active (err u405))
(define-constant err-invalid-project-title (err u406))
(define-constant err-invalid-impact-description (err u407))
(define-constant err-invalid-evidence-link (err u408))
(define-constant err-invalid-credit-amount (err u409))

;; Storage
(define-map carbon-projects uint {
  project-owner: principal,
  project-title: (string-utf8 64),
  impact-description: (string-utf8 256),
  evidence-documentation: (string-utf8 128),
  positive-audits: uint,
  negative-audits: uint,
  certification-status: (string-utf8 16),
  audit-deadline: uint
})

(define-map project-audits {project-id: uint, auditor: principal} bool)
(define-map participant-credits principal uint)
(define-data-var project-id-sequence uint u0)
(define-data-var minimum-audit-stake uint u75000000) ;; 75 credits
(define-data-var audit-review-period uint u576) ;; ~4 days in blocks

;; Initialize carbon credits for ecosystem
(define-public (mint-carbon-credits (credit-supply uint))
  (begin
    ;; Validate inputs
    (asserts! (> credit-supply u0) err-invalid-credit-amount)
    
    ;; Check authorization
    (asserts! (is-eq tx-sender contract-owner) err-not-permitted)
    
    ;; Mint credits
    (try! (ft-mint? carbon-credit credit-supply tx-sender))
    
    ;; Update participant credits
    (ok (map-set participant-credits tx-sender credit-supply))
  )
)

;; Submit carbon offset project for certification
(define-public (submit-project (project-title (string-utf8 64)) (impact-description (string-utf8 256)) (evidence-documentation (string-utf8 128)))
  (let
    ((project-owner tx-sender)
     (project-id (var-get project-id-sequence))
     (credit-balance (default-to u0 (map-get? participant-credits project-owner))))
    
    ;; Validate inputs
    (asserts! (> (len project-title) u0) err-invalid-project-title)
    (asserts! (> (len impact-description) u0) err-invalid-impact-description)
    (asserts! (> (len evidence-documentation) u0) err-invalid-evidence-link)
    
    ;; Check if project owner has enough credits
    (asserts! (>= credit-balance (var-get minimum-audit-stake)) err-insufficient-credits)
    
    ;; Store the carbon project
    (map-set carbon-projects project-id {
      project-owner: project-owner,
      project-title: project-title,
      impact-description: impact-description,
      evidence-documentation: evidence-documentation,
      positive-audits: u0,
      negative-audits: u0,
      certification-status: u"reviewing",
      audit-deadline: (+ burn-block-height (var-get audit-review-period))
    })
    
    ;; Increment the project ID sequence
    (var-set project-id-sequence (+ project-id u1))
    
    (ok project-id)))

;; Audit carbon offset project
(define-public (audit-project (project-id uint) (approve-project bool))
  (let
    ((project (unwrap! (map-get? carbon-projects project-id) err-project-not-found))
     (auditor tx-sender)
     (credit-balance (default-to u0 (map-get? participant-credits auditor)))
     (audit-key {project-id: project-id, auditor: auditor}))
    
    ;; Check if audit period is still active
    (asserts! (< burn-block-height (get audit-deadline project)) err-audit-period-closed)
    
    ;; Check if auditor has already audited
    (asserts! (is-none (map-get? project-audits audit-key)) err-already-audited)
    
    ;; Record the audit
    (map-set project-audits audit-key true)
    
    ;; Update audit counts
    (if approve-project
      (ok (map-set carbon-projects project-id (merge project {positive-audits: (+ (get positive-audits project) credit-balance)})))
      (ok (map-set carbon-projects project-id (merge project {negative-audits: (+ (get negative-audits project) credit-balance)})))
    )
  )
)

;; Finalize project certification
(define-public (finalize-certification (project-id uint))
  (let
    ((project (unwrap! (map-get? carbon-projects project-id) err-project-not-found)))
    
    ;; Check if audit period has ended
    (asserts! (>= burn-block-height (get audit-deadline project)) err-audit-still-active)
    
    ;; Update certification status
    (ok (map-set carbon-projects project-id 
      (merge project 
        {certification-status: (if (> (get positive-audits project) (get negative-audits project)) u"certified" u"rejected")})))
  )
)

;; Get carbon project details
(define-read-only (get-project (project-id uint))
  (map-get? carbon-projects project-id))

;; Get participant credit balance
(define-read-only (get-participant-credits (participant principal))
  (default-to u0 (map-get? participant-credits participant)))

;; Transfer carbon credits
(define-public (transfer-credits (credit-amount uint) (recipient principal))
  (let
    ((sender tx-sender)
     (sender-balance (default-to u0 (map-get? participant-credits sender)))
     (recipient-balance (default-to u0 (map-get? participant-credits recipient))))
    
    ;; Validate inputs
    (asserts! (> credit-amount u0) err-invalid-credit-amount)
    (asserts! (not (is-eq recipient 'SP000000000000000000002Q6VF78)) err-not-permitted)
    
    ;; Check if sender has enough credits
    (asserts! (>= sender-balance credit-amount) err-insufficient-credits)
    
    ;; Update balances
    (map-set participant-credits sender (- sender-balance credit-amount))
    (ok (map-set participant-credits recipient (+ recipient-balance credit-amount)))
  )
)