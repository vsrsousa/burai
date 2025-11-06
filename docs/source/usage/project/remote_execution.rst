Remote Job Execution via SSH
=============================

BURAI supports running Quantum ESPRESSO calculations on remote servers via SSH. 
This feature allows you to configure and submit jobs to high-performance computing 
clusters without manually transferring files or logging into remote systems.

Prerequisites
-------------

Before using remote execution, ensure:

1. You have SSH access to the remote server
2. The remote server has Quantum ESPRESSO installed
3. You have either:
   
   - SSH password authentication, or
   - SSH private key file for key-based authentication (recommended)

Configuring Remote Server
--------------------------

To configure a remote server connection:

**Step 1: Open Remote Configuration Dialog**

From the main menu, select:

- **File → Remote Configuration** (or equivalent menu option)

**Step 2: Add New Configuration**

1. Click the **[+]** button to create a new configuration
2. Enter a descriptive name for this server configuration (e.g., "HPC Cluster")
3. Click **OK**

**Step 3: Configure SSH Settings**

In the **SSH** tab, configure the connection parameters:

- **Host Name**: The hostname or IP address of the remote server (e.g., ``hpc.example.edu``)
- **Port**: The SSH port (default: 22)
- **Private Key**: Click the button to select your SSH private key file

  - Common locations: ``~/.ssh/id_rsa``, ``~/.ssh/id_ed25519``
  - The key file must be in OpenSSH format
  - If the button shows in red, the file path is invalid

**Step 4: Configure Account**

Still in the **SSH** tab, under the **Account** section:

- **User Name**: Your username on the remote server
- **Password**: (Optional) Your password if not using key-based authentication

**Note**: For security, key-based authentication is strongly recommended over password authentication.

**Step 5: Configure Job Submission**

In the **Command** tab, configure how jobs are submitted:

- **Post a Job**: The command template to submit jobs (e.g., ``qsub ${JOB_SCRIPT}``, ``sbatch ${JOB_SCRIPT}``)
- **Job Script**: The job script template (modify according to your cluster's requirements)

Common job schedulers:

+----------------+-------------------------+
| Scheduler      | Submit Command          |
+================+=========================+
| PBS/Torque     | ``qsub ${JOB_SCRIPT}``  |
+----------------+-------------------------+
| SLURM          | ``sbatch ${JOB_SCRIPT}``|
+----------------+-------------------------+
| SGE            | ``qsub ${JOB_SCRIPT}``  |
+----------------+-------------------------+
| Direct         | ``bash ${JOB_SCRIPT}``  |
+----------------+-------------------------+

**Step 6: Save Configuration**

Click **Close** to save the configuration.

Running Jobs Remotely
----------------------

Once you have configured a remote server:

**Step 1: Open Project**

Open or create a Quantum ESPRESSO project in BURAI.

**Step 2: Select Remote Execution**

1. From the project menu, select **Run**
2. In the run dialog, you will see options for:
   
   - **Local execution** (run on your computer)
   - **Remote execution** (run on configured SSH servers)

3. Select your configured remote server from the dropdown
4. Set the number of MPI processes and OpenMP threads
5. Click **OK**

**Step 3: Job Submission**

BURAI will automatically:

1. Connect to the remote server via SSH
2. Upload all necessary files:
   
   - Input files
   - Job script
   - Pseudopotential files

3. Submit the job using the configured command
4. Close the connection

You will see console output indicating the progress of these operations.

Authentication Methods
----------------------

SSH Private Key (Recommended)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Key-based authentication is more secure and convenient:

1. **Generate SSH Key Pair** (if you don't have one):

   .. code-block:: bash

      ssh-keygen -t ed25519 -C "your_email@example.com"

2. **Copy Public Key to Remote Server**:

   .. code-block:: bash

      ssh-copy-id user@remote-server.com

3. **Configure in BURAI**:
   
   - Click the **Private Key** button
   - Navigate to your private key file (e.g., ``~/.ssh/id_ed25519``)
   - Select the file

Password Authentication
^^^^^^^^^^^^^^^^^^^^^^^

While supported, password authentication is less secure:

1. Leave the **Private Key** field empty
2. Enter your password in the **Password** field
3. Note: Password is stored in plaintext in the configuration file

Job Script Customization
-------------------------

The job script template supports variable substitution:

+------------------------+----------------------------------------+
| Variable               | Description                            |
+========================+========================================+
| ``${QUANTUM_ESPRESSO_``| The Quantum ESPRESSO command           |
| ``COMMAND}``           |                                        |
+------------------------+----------------------------------------+
| ``${NCPU}``            | Total number of CPUs (MPI × OpenMP)    |
+------------------------+----------------------------------------+
| ``${NMPI}``            | Number of MPI processes                |
+------------------------+----------------------------------------+
| ``${NOMP}``            | Number of OpenMP threads               |
+------------------------+----------------------------------------+

Example job script for PBS/Torque:

.. code-block:: bash

   #!/bin/sh
   #PBS -q batch
   #PBS -l select=1:ncpus=${NCPU}:mpiprocs=${NMPI}:ompthreads=${NOMP}
   #PBS -l walltime=1:00:00
   #PBS -W group_list=mygroup

   if [ ! -z "${PBS_O_WORKDIR}" ]; then
     cd ${PBS_O_WORKDIR}
   fi

   ${QUANTUM_ESPRESSO_COMMAND}

Example job script for SLURM:

.. code-block:: bash

   #!/bin/bash
   #SBATCH --job-name=qe_job
   #SBATCH --ntasks=${NMPI}
   #SBATCH --cpus-per-task=${NOMP}
   #SBATCH --time=01:00:00
   #SBATCH --partition=normal

   ${QUANTUM_ESPRESSO_COMMAND}

Troubleshooting
---------------

Connection Failed
^^^^^^^^^^^^^^^^^

If SSH connection fails:

1. Verify the hostname and port are correct
2. Test connection manually: ``ssh -p PORT user@hostname``
3. Check that the private key file exists and has correct permissions (``chmod 600 ~/.ssh/id_rsa``)
4. Ensure the remote server allows SSH connections

Private Key Not Working
^^^^^^^^^^^^^^^^^^^^^^^^

If private key authentication fails:

1. Verify the key is in OpenSSH format (not PuTTY .ppk format)
2. Convert PuTTY keys using: ``puttygen key.ppk -O private-openssh -o id_rsa``
3. Ensure your public key is in ``~/.ssh/authorized_keys`` on the remote server
4. Check file permissions: private key should be 600, public key 644

Job Not Submitted
^^^^^^^^^^^^^^^^^

If job submission fails:

1. Check the console output for error messages
2. Verify the job submission command is correct for your scheduler
3. Test the command manually on the remote server
4. Ensure you have permission to submit jobs
5. Check that the queue/partition name is valid

File Upload Failed
^^^^^^^^^^^^^^^^^^

If file transfer fails:

1. Verify you have write permission in the remote directory
2. Check available disk space on the remote server
3. Ensure the SFTP subsystem is enabled on the remote server

Security Considerations
-----------------------

1. **Use Key-Based Authentication**: More secure than passwords
2. **Protect Private Keys**: Keep private key files secure with proper permissions
3. **Avoid Password Storage**: Use keys instead of storing passwords
4. **Verify Host Keys**: On first connection, verify the server's fingerprint
5. **Use Strong Passphrases**: Protect private keys with passphrases when possible

Technical Details
-----------------

Implementation
^^^^^^^^^^^^^^

BURAI uses the JSch library for SSH/SFTP communication:

- **SSH Protocol**: SSH-2
- **SFTP**: For secure file transfer
- **Authentication**: Supports both password and public key authentication
- **Host Key Verification**: Currently set to "no" (accepts any host key)

The remote execution workflow:

1. Establish SSH connection using configured credentials
2. Open SFTP channel for file transfers
3. Upload input files, pseudopotentials, and job script
4. Open SSH execution channel
5. Execute job submission command
6. Capture and display command output
7. Close all channels and disconnect

Limitations
^^^^^^^^^^^

- No interactive job monitoring (jobs run independently on remote server)
- Results must be retrieved manually or through separate mechanisms
- Limited to single directory (no automatic working directory creation)
- No automatic result synchronization back to local machine
