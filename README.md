# PrimeLaunch

PrimeLaunch is a decentralized collaborative writing platform that transforms content creation through atomic contribution tracking and dynamic revenue distribution. The platform introduces "narrative DNA" technology where every creative element is cryptographically attributed to specific contributors, enabling writers to collaborate seamlessly while maintaining complete ownership transparency.

# PrimeLaunch Smart Contract

A Stacks Clarity smart contract for decentralized collaborative writing with atomic contribution tracking and dynamic revenue distribution.

## Overview

PrimeLaunch transforms content creation through blockchain technology, enabling writers to collaborate seamlessly while maintaining complete ownership transparency. The platform uses smart contracts to track contributions, calculate impact scores, and automatically distribute PRIME token rewards.

## Features

- **Content Creation**: Create and manage collaborative writing projects as on-chain NFTs
- **Contribution Tracking**: Every edit and contribution is cryptographically recorded with unique hashes
- **Dynamic Collaboration**: Add collaborators with granular permission controls
- **Automated Rewards**: PRIME tokens automatically distributed based on approved contribution weights
- **Revenue Sharing**: Transparent, automated royalty distribution among contributors
- **Version Control**: Update content hashes to track evolution of collaborative works

## Smart Contract Architecture

### Data Structures

#### Contents
Stores metadata for each piece of collaborative content:
- `creator`: Principal address of content creator
- `title`: Content title (max 256 characters)
- `content-hash`: Cryptographic hash of content (32 bytes)
- `total-contributions`: Count of approved contributions
- `status`: Content status (e.g., "active", "published", "archived")
- `created-at`: Block height when content was created

#### Contributions
Tracks individual contributions to content:
- `content-id`: Associated content identifier
- `contributor`: Principal address of contributor
- `contribution-hash`: Hash of the contribution
- `weight`: Contribution impact score (1-100)
- `approved`: Approval status
- `timestamp`: Block height of submission

#### Contributor Weights
Aggregated contribution scores per contributor per content piece

#### PRIME Balances
Token balances for all platform users

#### Revenue Shares
Percentage-based revenue distribution mapping

## Core Functions

### Read-Only Functions

#### `get-content (content-id uint)`
Retrieves content metadata by ID.

**Returns**: Content record or none

#### `get-contribution (contribution-id uint)`
Retrieves contribution details by ID.

**Returns**: Contribution record or none

#### `get-contributor-weight (content-id uint) (contributor principal)`
Gets the aggregated contribution weight for a specific contributor on a content piece.

**Returns**: Weight as uint (default 0)

#### `get-prime-balance (account principal)`
Retrieves PRIME token balance for an account.

**Returns**: Balance as uint (default 0)

#### `get-revenue-share (content-id uint) (contributor principal)`
Gets the revenue share percentage for a contributor.

**Returns**: Share percentage as uint (default 0)

#### `is-collaborator (content-id uint) (collaborator principal)`
Checks if an address is an authorized collaborator.

**Returns**: Boolean

### Public Functions

#### `create-content (title (string-ascii 256)) (content-hash (buff 32))`
Creates a new content piece on the platform.

**Parameters**:
- `title`: Content title
- `content-hash`: SHA-256 hash of initial content

**Returns**: Content ID

**Access**: Anyone

**Effects**:
- Creates new content record
- Sets creator as initial collaborator
- Initializes creator with 100% weight and revenue share

#### `add-collaborator (content-id uint) (collaborator principal)`
Adds a new collaborator to a content piece.

**Parameters**:
- `content-id`: Target content ID
- `collaborator`: Principal address to add

**Returns**: Boolean success

**Access**: Content creator only

#### `submit-contribution (content-id uint) (contribution-hash (buff 32)) (weight uint)`
Submits a contribution for review.

**Parameters**:
- `content-id`: Target content ID
- `contribution-hash`: Hash of the contribution
- `weight`: Self-assessed impact score (1-100)

**Returns**: Contribution ID

**Access**: Authorized collaborators only

**Effects**:
- Creates pending contribution record
- Awaits creator approval

#### `approve-contribution (contribution-id uint)`
Approves a pending contribution.

**Parameters**:
- `contribution-id`: ID of contribution to approve

**Returns**: Boolean success

**Access**: Content creator only

**Effects**:
- Marks contribution as approved
- Updates contributor weight
- Mints PRIME tokens (weight × 10) to contributor
- Increments total contributions counter

#### `calculate-revenue-shares (content-id uint)`
Triggers revenue share calculation (framework function).

**Parameters**:
- `content-id`: Target content ID

**Returns**: Boolean success

**Access**: Content creator only

**Note**: In production, this would calculate proportional shares based on all contributor weights.

#### `update-revenue-share (content-id uint) (contributor principal) (share uint)`
Manually sets revenue share for a contributor.

**Parameters**:
- `content-id`: Target content ID
- `contributor`: Contributor principal
- `share`: Percentage share (0-100)

**Returns**: Boolean success

**Access**: Content creator only

#### `transfer-prime (amount uint) (recipient principal)`
Transfers PRIME tokens between accounts.

**Parameters**:
- `amount`: Number of tokens to transfer
- `recipient`: Receiving principal address

**Returns**: Boolean success

**Access**: Anyone with sufficient balance

#### `update-content-status (content-id uint) (new-status (string-ascii 20))`
Updates the status of a content piece.

**Parameters**:
- `content-id`: Target content ID
- `new-status`: New status string (e.g., "published", "archived")

**Returns**: Boolean success

**Access**: Content creator only

#### `update-content-hash (content-id uint) (new-hash (buff 32))`
Updates content hash for versioning.

**Parameters**:
- `content-id`: Target content ID
- `new-hash`: New content hash

**Returns**: Boolean success

**Access**: Authorized collaborators only

## PRIME Tokenomics

- **Total Supply**: 1,000,000,000 PRIME tokens
- **Reward Mechanism**: Contributors earn PRIME tokens based on approved contribution weights
- **Calculation**: Reward = Weight × 10 PRIME tokens
- **Example**: A contribution with weight 50 earns 500 PRIME tokens

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-owner-only` | Action restricted to contract owner |
| u101 | `err-not-found` | Content or contribution not found |
| u102 | `err-unauthorized` | Caller lacks required permissions |
| u103 | `err-already-exists` | Resource already exists |
| u104 | `err-invalid-params` | Invalid function parameters |
| u105 | `err-insufficient-balance` | Insufficient token balance |

## Usage Examples

### Creating Content

```clarity
(contract-call? .primelaunch create-content 
    "My Collaborative Novel" 
    0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef)
```

### Adding a Collaborator

```clarity
(contract-call? .primelaunch add-collaborator 
    u1 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Submitting a Contribution

```clarity
(contract-call? .primelaunch submit-contribution 
    u1 
    0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
    u75)
```

### Approving a Contribution

```clarity
(contract-call? .primelaunch approve-contribution u1)
```

### Transferring PRIME Tokens

```clarity
(contract-call? .primelaunch transfer-prime 
    u1000 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Security Considerations

1. **Access Control**: Only content creators can approve contributions and manage collaborators
2. **Contribution Validation**: Weights are validated to be between 1-100
3. **Balance Checks**: Token transfers verify sufficient balance before execution
4. **Collaborator Verification**: Only authorized collaborators can submit contributions
5. **Immutable Records**: Contributions and content records are cryptographically verifiable

## Development Roadmap

### Current Implementation
- ✅ Basic content creation and management
- ✅ Contribution tracking and approval
- ✅ PRIME token minting and transfers
- ✅ Collaborator management
- ✅ Revenue share framework

### Future Enhancements
- Automated revenue share calculation based on contribution weights
- Multi-signature approval for high-value content
- Merkle tree verification for content integrity
- Integration with external publishing platforms
- Advanced governance mechanisms
- Dispute resolution system
- NFT marketplace integration

## Deployment

### Prerequisites
- Stacks blockchain node or access to a public node
- Clarity CLI or Clarinet for testing and deployment
- Stacks wallet with STX for deployment fees

### Steps

1. **Install Clarinet** (recommended)
```bash
curl -L https://www.hiro.so/clarinet/install.sh | sh
```

2. **Initialize Project**
```bash
clarinet new primelaunch-project
cd primelaunch-project
```

3. **Add Contract**
Copy `primelaunch.clar` to `contracts/` directory

4. **Check Contract**
```bash
clarinet check
```

5. **Deploy to Testnet**
```bash
clarinet deploy --testnet
```

6. **Deploy to Mainnet**
```bash
clarinet deploy --mainnet
```

## Integration Guide

### Frontend Integration

```javascript
// Using @stacks/transactions
import { 
    makeContractCall, 
    bufferCV, 
    uintCV, 
    stringAsciiCV 
} from '@stacks/transactions';

// Create content
const createContent = async (title, contentHash) => {
    const txOptions = {
        contractAddress: 'ST...',
        contractName: 'primelaunch',
        functionName: 'create-content',
        functionArgs: [
            stringAsciiCV(title),
            bufferCV(Buffer.from(contentHash, 'hex'))
        ],
        network: 'testnet'
    };
    
    return await makeContractCall(txOptions);
