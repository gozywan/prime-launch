;; PrimeLaunch - Decentralized Collaborative Writing Platform
;; This contract manages content creation, contribution tracking, and PRIME token distribution

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-params (err u104))
(define-constant err-insufficient-balance (err u105))

;; Data Variables
(define-data-var content-nonce uint u0)
(define-data-var contribution-nonce uint u0)
(define-data-var total-prime-supply uint u1000000000) ;; 1 billion PRIME tokens

;; Data Maps

;; Content registry - stores metadata for each piece of content
(define-map contents
    uint
    {
        creator: principal,
        title: (string-ascii 256),
        content-hash: (buff 32),
        total-contributions: uint,
        status: (string-ascii 20),
        created-at: uint
    }
)

;; Contribution tracking - tracks individual contributions to content
(define-map contributions
    uint
    {
        content-id: uint,
        contributor: principal,
        contribution-hash: (buff 32),
        weight: uint,
        approved: bool,
        timestamp: uint
    }
)

;; Contributor weights per content - aggregated contribution scores
(define-map contributor-weights
    {content-id: uint, contributor: principal}
    uint
)

;; PRIME token balances
(define-map prime-balances
    principal
    uint
)

;; Content collaborators - who has permission to contribute
(define-map content-collaborators
    {content-id: uint, collaborator: principal}
    bool
)

;; Revenue shares - percentage of revenue for each contributor
(define-map revenue-shares
    {content-id: uint, contributor: principal}
    uint
)

;; Read-only functions

(define-read-only (get-content (content-id uint))
    (map-get? contents content-id)
)

(define-read-only (get-contribution (contribution-id uint))
    (map-get? contributions contribution-id)
)

(define-read-only (get-contributor-weight (content-id uint) (contributor principal))
    (default-to u0 (map-get? contributor-weights {content-id: content-id, contributor: contributor}))
)

(define-read-only (get-prime-balance (account principal))
    (default-to u0 (map-get? prime-balances account))
)

(define-read-only (get-revenue-share (content-id uint) (contributor principal))
    (default-to u0 (map-get? revenue-shares {content-id: content-id, contributor: contributor}))
)

(define-read-only (is-collaborator (content-id uint) (collaborator principal))
    (default-to false (map-get? content-collaborators {content-id: content-id, collaborator: collaborator}))
)

(define-read-only (get-content-nonce)
    (var-get content-nonce)
)

(define-read-only (get-contribution-nonce)
    (var-get contribution-nonce)
)

;; Private functions

(define-private (mint-prime-tokens (recipient principal) (amount uint))
    (let
        (
            (current-balance (get-prime-balance recipient))
        )
        (map-set prime-balances recipient (+ current-balance amount))
        true
    )
)

;; Public functions

;; Create new content
(define-public (create-content (title (string-ascii 256)) (content-hash (buff 32)))
    (let
        (
            (content-id (+ (var-get content-nonce) u1))
        )
        (asserts! (> (len title) u0) err-invalid-params)
        (map-set contents content-id {
            creator: tx-sender,
            title: title,
            content-hash: content-hash,
            total-contributions: u0,
            status: "active",
            created-at: block-height
        })
        (map-set content-collaborators {content-id: content-id, collaborator: tx-sender} true)
        (map-set contributor-weights {content-id: content-id, contributor: tx-sender} u100)
        (map-set revenue-shares {content-id: content-id, contributor: tx-sender} u100)
        (var-set content-nonce content-id)
        (ok content-id)
    )
)

;; Add collaborator to content
(define-public (add-collaborator (content-id uint) (collaborator principal))
    (let
        (
            (content (unwrap! (map-get? contents content-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (map-set content-collaborators {content-id: content-id, collaborator: collaborator} true)
        (ok true)
    )
)

;; Submit contribution
(define-public (submit-contribution (content-id uint) (contribution-hash (buff 32)) (weight uint))
    (let
        (
            (content (unwrap! (map-get? contents content-id) err-not-found))
            (contribution-id (+ (var-get contribution-nonce) u1))
        )
        (asserts! (is-collaborator content-id tx-sender) err-unauthorized)
        (asserts! (> weight u0) err-invalid-params)
        (asserts! (<= weight u100) err-invalid-params)
        
        (map-set contributions contribution-id {
            content-id: content-id,
            contributor: tx-sender,
            contribution-hash: contribution-hash,
            weight: weight,
            approved: false,
            timestamp: block-height
        })
        
        (var-set contribution-nonce contribution-id)
        (ok contribution-id)
    )
)

;; Approve contribution (by content creator)
(define-public (approve-contribution (contribution-id uint))
    (let
        (
            (contribution (unwrap! (map-get? contributions contribution-id) err-not-found))
            (content-id (get content-id contribution))
            (content (unwrap! (map-get? contents content-id) err-not-found))
            (contributor (get contributor contribution))
            (weight (get weight contribution))
            (current-weight (get-contributor-weight content-id contributor))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (asserts! (not (get approved contribution)) err-already-exists)
        
        ;; Update contribution status
        (map-set contributions contribution-id
            (merge contribution {approved: true})
        )
        
        ;; Update contributor weight
        (map-set contributor-weights 
            {content-id: content-id, contributor: contributor}
            (+ current-weight weight)
        )
        
        ;; Update content total contributions
        (map-set contents content-id
            (merge content {total-contributions: (+ (get total-contributions content) u1)})
        )
        
        ;; Mint PRIME tokens as reward (weight * 10 tokens)
        (begin
            (mint-prime-tokens contributor (* weight u10))
            (ok true)
        )
    )
)

;; Calculate and distribute revenue shares
(define-public (calculate-revenue-shares (content-id uint))
    (let
        (
            (content (unwrap! (map-get? contents content-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        ;; In a full implementation, this would iterate through all contributors
        ;; and calculate their proportional share based on weights
        ;; For now, we'll update individual shares via update-revenue-share
        (ok true)
    )
)

;; Update revenue share for a contributor
(define-public (update-revenue-share (content-id uint) (contributor principal) (share uint))
    (let
        (
            (content (unwrap! (map-get? contents content-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (asserts! (<= share u100) err-invalid-params)
        (map-set revenue-shares {content-id: content-id, contributor: contributor} share)
        (ok true)
    )
)

;; Transfer PRIME tokens
(define-public (transfer-prime (amount uint) (recipient principal))
    (let
        (
            (sender-balance (get-prime-balance tx-sender))
        )
        (asserts! (>= sender-balance amount) err-insufficient-balance)
        (map-set prime-balances tx-sender (- sender-balance amount))
        (mint-prime-tokens recipient amount)
        (ok true)
    )
)

;; Update content status
(define-public (update-content-status (content-id uint) (new-status (string-ascii 20)))
    (let
        (
            (content (unwrap! (map-get? contents content-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (map-set contents content-id
            (merge content {status: new-status})
        )
        (ok true)
    )
)

;; Update content hash (for versioning)
(define-public (update-content-hash (content-id uint) (new-hash (buff 32)))
    (let
        (
            (content (unwrap! (map-get? contents content-id) err-not-found))
        )
        (asserts! (is-collaborator content-id tx-sender) err-unauthorized)
        (map-set contents content-id
            (merge content {content-hash: new-hash})
        )
        (ok true)
    )
)
