# SSH Remote Execution Implementation

## Overview

This package provides SSH-based remote job execution functionality for BURAI. It allows users to submit Quantum ESPRESSO calculations to remote servers via SSH, supporting both password and private key authentication.

## Components

### SSHServer

Model class representing a remote SSH server configuration.

**Properties:**
- `title`: Configuration name
- `host`: Remote server hostname/IP
- `port`: SSH port (default: 22)
- `user`: SSH username
- `password`: Password for authentication (optional)
- `keyPath`: Path to SSH private key file (optional)
- `jobCommand`: Command template for job submission (e.g., "qsub ${JOB_SCRIPT}")
- `jobScript`: Job script template with variable placeholders

**Variable Substitution:**
- `${QUANTUM_ESPRESSO_COMMAND}` - QE command
- `${NCPU}` - Total CPUs (MPI × OpenMP)
- `${NMPI}` - Number of MPI processes
- `${NOMP}` - Number of OpenMP threads
- `${JOB_SCRIPT}` - Script filename (in jobCommand only)

### SSHServerList

Singleton manager for SSH server configurations.

**Features:**
- Persists configurations to JSON file
- Provides CRUD operations for server configs
- Loads configurations on startup

### SSHJob

Handles the actual SSH connection and remote job submission.

**Key Methods:**

#### `postJobToServer()`
Main entry point that orchestrates the complete workflow:
1. Sets up local files (input files, pseudopotentials, job script)
2. Establishes SSH connection
3. Uploads all files via SFTP
4. Executes job submission command
5. Cleans up and disconnects

#### `connectSSH()`
Establishes SSH connection using JSch library.

**Authentication Flow:**
1. If `keyPath` is specified:
   - Validates key file exists
   - Adds identity to JSch
   - Uses key-based authentication
2. If `password` is specified (and no key):
   - Uses password authentication
3. Opens SFTP channel for file transfers

**Configuration:**
- Connection timeout: 30 seconds
- StrictHostKeyChecking: disabled (accepts any host key)

#### `ftpFile(File)`
Uploads a single file to remote server via SFTP.

- Uploads to current working directory
- Preserves original filename
- Error handling for network issues

#### `executeRemoteCommand(String)`
Executes a command on the remote server.

**Features:**
- Captures stdout and stderr
- Returns success/failure based on exit status
- Logs all output for debugging

#### `disconnectSSH()`
Properly closes SFTP channel and SSH session.

## Authentication Methods

### Private Key Authentication (Recommended)

**Supported Key Types:**
- RSA
- DSA  
- ECDSA
- Ed25519

**Key Format:**
- OpenSSH format (default from ssh-keygen)
- PEM format

**Not Supported:**
- PuTTY .ppk format (must be converted)

**Setup:**
```bash
# Generate key pair
ssh-keygen -t ed25519 -C "user@example.com"

# Copy public key to server
ssh-copy-id user@remote-server.com
```

### Password Authentication

Less secure but supported for convenience. Password is stored in plaintext in the configuration file.

## Usage Example

```java
// Create server configuration
SSHServer server = new SSHServer("My HPC Cluster");
server.setHost("hpc.example.edu");
server.setPort("22");
server.setUser("username");
server.setKeyPath("/home/user/.ssh/id_rsa");
server.setJobCommand("qsub ${JOB_SCRIPT}");

// Create and submit job
SSHJob job = new SSHJob(project, server);
job.setType(RunningType.SCF);
job.setNumProcesses(16);
job.setNumThreads(1);

boolean success = job.postJobToServer();
```

## Error Handling

All methods implement comprehensive error handling:

- **Connection Errors**: Logged to stderr, returns false
- **Authentication Errors**: Logged with details about key/password issues
- **File Transfer Errors**: Individual files logged, continues with remaining files
- **Command Execution Errors**: Captures exit status and error output

## Security Considerations

### Current Implementation

⚠️ **StrictHostKeyChecking is disabled** - This accepts any host key without verification. In production, this should be improved to:

1. Verify host keys on first connection
2. Store trusted host keys
3. Warn on host key changes

### Recommendations

1. **Use Key Authentication**: More secure than passwords
2. **Protect Private Keys**: Ensure correct file permissions (600)
3. **Don't Store Passwords**: Use keys instead
4. **Implement Host Key Verification**: Planned future enhancement
5. **Use Key Passphrases**: Additional layer of security

## Dependencies

- **JSch 0.1.54**: SSH/SFTP implementation
- Java 8+
- Network access to remote servers

## Limitations

1. **No Result Retrieval**: Files uploaded but results must be retrieved separately
2. **No Job Monitoring**: Job runs independently, no status tracking
3. **Single Directory**: No automatic directory structure creation
4. **No Host Key Verification**: Currently accepts any host key
5. **No Connection Pooling**: New connection per job submission

## Future Enhancements

- [ ] Result file synchronization back to local
- [ ] Job status monitoring
- [ ] Connection pooling for multiple submissions
- [ ] Host key verification and management
- [ ] Support for SSH agents
- [ ] Support for jump hosts/bastions
- [ ] Asynchronous file uploads
- [ ] Progress callbacks for large file transfers
- [ ] Remote working directory configuration
- [ ] SSH config file support (~/.ssh/config)

## Troubleshooting

### Common Issues

**"Failed to establish SSH connection"**
- Check hostname and port
- Verify network connectivity
- Test with: `ssh user@host -p port`

**"Private key file not found"**
- Verify file path is absolute
- Check file exists and is readable
- Ensure correct permissions (600)

**"Failed to upload file"**
- Verify write permissions on remote
- Check disk space
- Ensure SFTP subsystem enabled

**"Failed to submit job"**
- Verify job command syntax
- Check queue/partition name
- Ensure user has submit permissions

### Debug Output

All operations log to stdout/stderr:
- Connection status
- File upload confirmation
- Command execution output
- Error details

Enable Java logging for more details:
```java
System.setProperty("jsch.debug", "true");
```

## References

- [JSch Documentation](http://www.jcraft.com/jsch/)
- [SSH Protocol RFC 4253](https://tools.ietf.org/html/rfc4253)
- [OpenSSH Manual](https://www.openssh.com/manual.html)
