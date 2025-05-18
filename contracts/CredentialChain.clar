;; CredentialChain - A verifiable credentials and certification system
;; This contract allows issuers to create verifiable credentials that can be recognized by multiple verifiers

(define-non-fungible-token credential uint)

;; Data storage
(define-map credential-details uint {title: (string-ascii 64), description: (string-ascii 256), badge-uri: (string-utf8 256)})
(define-map credential-claims uint (list 20 {field: (string-ascii 32), value: (string-ascii 64)}))
(define-map issuer-registry principal {name: (string-ascii 64), active: bool})
(define-map verifier-credential-trust {verifier-id: principal, credential-id: uint} {trusted: bool, trust-level: uint})
(define-map credential-ownership uint principal)

;; Error codes
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ISSUER_NOT_REGISTERED (err u101))
(define-constant ERR_CREDENTIAL_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_REGISTERED (err u103))
(define-constant ERR_INVALID_PARAMS (err u104))
(define-constant ERR_NOT_OWNER (err u105))
(define-constant ERR_INVALID_PRINCIPAL (err u106))
(define-constant ERR_EMPTY_STRING (err u107))
(define-constant ERR_INVALID_VALUE (err u108))

;; Constants
(define-constant ZERO_ADDRESS 'SP000000000000000000002Q6VF78)
(define-constant MAX_TRUST_LEVEL u1000)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Admin functions
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    ;; Validate new owner is not zero address
    (asserts! (not (is-eq new-owner ZERO_ADDRESS)) ERR_INVALID_PRINCIPAL)
    (ok (var-set contract-owner new-owner))))

;; Issuer registration
(define-public (register-issuer (issuer-name (string-ascii 64)))
  (begin
    ;; Validate issuer name is not empty
    (asserts! (> (len issuer-name) u0) ERR_EMPTY_STRING)
    (let ((issuer-exists (default-to {name: "", active: false} (map-get? issuer-registry tx-sender))))
      (asserts! (not (get active issuer-exists)) ERR_ALREADY_REGISTERED)
      (ok (map-set issuer-registry tx-sender {name: issuer-name, active: true})))))

(define-public (deactivate-issuer)
  (let ((issuer-exists (default-to {name: "", active: false} (map-get? issuer-registry tx-sender))))
    (asserts! (get active issuer-exists) ERR_ISSUER_NOT_REGISTERED)
    (ok (map-set issuer-registry tx-sender 
      {name: (get name issuer-exists), active: false}))))

;; NFT functions
(define-public (issue-credential 
    (recipient principal) 
    (credential-id uint) 
    (title (string-ascii 64)) 
    (description (string-ascii 256)) 
    (badge-uri (string-utf8 256)))
  (begin
    (asserts! (or (is-eq tx-sender (var-get contract-owner)) 
                 (is-some (map-get? issuer-registry tx-sender))) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (nft-get-owner? credential credential-id)) ERR_ALREADY_REGISTERED)
    
    ;; Validate recipient is not zero address
    (asserts! (not (is-eq recipient ZERO_ADDRESS)) ERR_INVALID_PRINCIPAL)
    ;; Validate strings are not empty
    (asserts! (> (len title) u0) ERR_EMPTY_STRING)
    (asserts! (> (len description) u0) ERR_EMPTY_STRING)
    (asserts! (> (len badge-uri) u0) ERR_EMPTY_STRING)
    
    (try! (nft-mint? credential credential-id recipient))
    (map-set credential-details credential-id {title: title, description: description, badge-uri: badge-uri})
    (map-set credential-ownership credential-id recipient)
    (ok credential-id)))

(define-public (transfer-credential (credential-id uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? credential credential-id) ERR_CREDENTIAL_NOT_FOUND)) ERR_NOT_OWNER)
    ;; Validate recipient is not zero address
    (asserts! (not (is-eq recipient ZERO_ADDRESS)) ERR_INVALID_PRINCIPAL)
    (try! (nft-transfer? credential credential-id tx-sender recipient))
    (map-set credential-ownership credential-id recipient)
    (ok true)))

;; Verifier trust functions
(define-public (set-credential-trust (credential-id uint) (trust-level uint) (trusted bool))
  (begin
    (asserts! (is-some (map-get? issuer-registry tx-sender)) ERR_ISSUER_NOT_REGISTERED)
    (asserts! (is-some (nft-get-owner? credential credential-id)) ERR_CREDENTIAL_NOT_FOUND)
    ;; Validate trust level is within acceptable range
    (asserts! (<= trust-level MAX_TRUST_LEVEL) ERR_INVALID_VALUE)
    (ok (map-set verifier-credential-trust {verifier-id: tx-sender, credential-id: credential-id} 
                {trusted: trusted, trust-level: trust-level}))))

;; Helper function to validate claims
(define-private (validate-claim (claim {field: (string-ascii 32), value: (string-ascii 64)}))
  (and (> (len (get field claim)) u0) (> (len (get value claim)) u0)))

(define-private (validate-claims (claims (list 20 {field: (string-ascii 32), value: (string-ascii 64)})))
  (let ((claims-len (len claims)))
    (and 
      (> claims-len u0)
      (is-eq claims-len (len (filter validate-claim claims))))))

;; Credential claim functions
(define-public (set-credential-claims (credential-id uint) (claims (list 20 {field: (string-ascii 32), value: (string-ascii 64)})))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (is-some (nft-get-owner? credential credential-id)) ERR_CREDENTIAL_NOT_FOUND)
    ;; Validate claims
    (asserts! (validate-claims claims) ERR_INVALID_VALUE)
    (ok (map-set credential-claims credential-id claims))))

;; Read-only functions
(define-read-only (get-credential-details (credential-id uint))
  (map-get? credential-details credential-id))

(define-read-only (get-credential-claims (credential-id uint))
  (map-get? credential-claims credential-id))

(define-read-only (get-credential-trust (verifier-id principal) (credential-id uint))
  (map-get? verifier-credential-trust {verifier-id: verifier-id, credential-id: credential-id}))

(define-read-only (get-issuer-info (issuer-id principal))
  (map-get? issuer-registry issuer-id))

(define-read-only (get-credential-owner (credential-id uint))
  (nft-get-owner? credential credential-id))

(define-read-only (is-issuer-active (issuer-id principal))
  (match (map-get? issuer-registry issuer-id)
    issuer-data (get active issuer-data)
    false))