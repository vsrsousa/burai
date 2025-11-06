# Remote SSH Job Execution - Quick Start Guide

This guide shows you how to run Quantum ESPRESSO jobs on a remote server using SSH.

## Step 1: Generate SSH Key (First Time Only)

Open a terminal and generate an SSH key pair:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Press Enter to accept the default location (`~/.ssh/id_ed25519`).
You can optionally set a passphrase for extra security (press Enter to skip).

## Step 2: Copy Your Public Key to the Remote Server

```bash
ssh-copy-id username@remote-server.com
```

Replace `username` with your username and `remote-server.com` with your server's address.

Test the connection:
```bash
ssh username@remote-server.com
```

If you can log in without entering a password, key authentication is working!

## Step 3: Configure BURAI

1. **Open Remote Configuration**
   - Launch BURAI
   - Go to: File → Remote Configuration (or similar menu option)

2. **Create New Configuration**
   - Click the **[+]** button
   - Enter a name: "My HPC Server"
   - Click **OK**

3. **Configure SSH Settings** (in the SSH tab)
   - **Host Name**: `remote-server.com`
   - **Port**: `22` (default)
   - **User Name**: `username`
   - **Private Key**: Click the button and select `~/.ssh/id_ed25519`
   - **Password**: Leave empty (we're using key authentication)

4. **Configure Job Commands** (in the Command tab)
   - **Work Directory**: `/scratch/username/burai_jobs` (optional - remote path for job files)
   - **Module Commands**: `module load quantum-espresso/6.8` (optional - modules to load)
   - **Post a Job**: `qsub ${JOB_SCRIPT}` (or `sbatch` for SLURM)
   - **Job Script**: Modify the template for your cluster's requirements

5. **Save**
   - Click **Close** to save the configuration

## Step 4: Run a Job

1. **Open a Project**
   - Create or open a Quantum ESPRESSO project in BURAI

2. **Start Remote Run**
   - Select **Run** from the project menu
   - Choose your configured remote server
   - Set MPI processes and OpenMP threads
   - Click **OK**

3. **Monitor Progress**
   - Check the console output for upload and submission confirmation
   - Files are uploaded and the job is submitted automatically

## Example Job Script Templates

### PBS/Torque (with modules)
```bash
#!/bin/sh
#PBS -q batch
#PBS -l select=1:ncpus=${NCPU}:mpiprocs=${NMPI}:ompthreads=${NOMP}
#PBS -l walltime=1:00:00
#PBS -W group_list=mygroup

if [ ! -z "${PBS_O_WORKDIR}" ]; then
  cd ${PBS_O_WORKDIR}
fi

# Load required modules
${MODULE_COMMANDS}

${QUANTUM_ESPRESSO_COMMAND}
```

### SLURM (with modules)
```bash
#!/bin/bash
#SBATCH --job-name=qe_job
#SBATCH --ntasks=${NMPI}
#SBATCH --cpus-per-task=${NOMP}
#SBATCH --time=01:00:00
#SBATCH --partition=normal

# Load required modules
${MODULE_COMMANDS}

${QUANTUM_ESPRESSO_COMMAND}
```

### Direct Execution (No Scheduler)
```bash
#!/bin/bash
cd $HOME/calculations
${QUANTUM_ESPRESSO_COMMAND}
```

## Working with Custom Directories and Modules

### Remote Working Directory

You can specify a custom directory on the remote server where files will be uploaded and jobs will run:

1. In the **Command** tab, set **Work Directory** to your desired path
   - Example: `/scratch/username/burai_jobs`
   - Example: `/work/myproject/calculations`

2. BURAI will:
   - Create the directory if it doesn't exist (including parent directories)
   - Upload all files to this directory
   - Run the job submission command from this directory

**Benefits:**
- Keep jobs organized in scratch space
- Avoid cluttering home directory
- Use fast scratch filesystems
- Easy cleanup after jobs complete

### Module Loading

Many HPC systems use environment modules to manage software. You can configure module commands:

1. In the **Command** tab, set **Module Commands**
   - Single module: `module load quantum-espresso/6.8`
   - Multiple modules: `module load intel/2021.1; module load openmpi/4.1.0; module load quantum-espresso/6.8`

2. These commands will be inserted into the job script before the Quantum ESPRESSO command

**Common Examples:**
```bash
# Load single module
module load quantum-espresso/7.0

# Load compiler and QE
module load intel/2021; module load quantum-espresso

# Load with specific versions
module load gcc/11.2.0; module load openmpi/4.1.1; module load qe/7.0

# Purge and load
module purge; module load quantum-espresso/latest
```

### Complete Example Configuration

**Work Directory:** `/scratch/jsmith/qe_calculations`

**Module Commands:** `module load intel/2021.4; module load openmpi/4.1.1; module load quantum-espresso/7.0`

**Post a Job:** `sbatch ${JOB_SCRIPT}`

**Result:** Files are uploaded to `/scratch/jsmith/qe_calculations`, modules are loaded in the job script, and the job is submitted via SLURM.

## Troubleshooting

### Cannot Connect
- Verify hostname: `ping remote-server.com`
- Test SSH manually: `ssh username@remote-server.com`
- Check firewall settings

### Private Key Not Working
- Check file permissions: `chmod 600 ~/.ssh/id_ed25519`
- Verify public key on server: `cat ~/.ssh/authorized_keys` (on remote)
- Make sure you selected the **private** key, not the .pub file

### Job Not Submitting
- Log into the server and test the command manually
- Check queue name: `qstat -Q` (PBS) or `sinfo` (SLURM)
- Verify you have permission to submit jobs

## What Gets Uploaded

BURAI automatically uploads:
- Input files (.in)
- Pseudopotential files
- Job submission script

These files are uploaded to your home directory on the remote server.

## What Happens Next

After submission:
1. Your job enters the queue on the remote server
2. The job runs when resources are available
3. Output files are created on the remote server
4. You need to retrieve results manually (SFTP, scp, or rsync)

## Retrieving Results

To get your results back:

### Using Command Line
```bash
# Download entire directory
scp -r username@remote-server.com:~/project_name ./

# Or use rsync
rsync -avz username@remote-server.com:~/project_name ./
```

### Using SFTP GUI
- FileZilla: sftp://remote-server.com
- WinSCP (Windows)
- Cyberduck (Mac)

## Security Best Practices

1. ✅ Use SSH keys instead of passwords
2. ✅ Keep private keys secure (chmod 600)
3. ✅ Use strong passphrases on keys (optional)
4. ✅ Don't share private keys
5. ⚠️ Be aware that host key verification is currently disabled

## Need Help?

See the full documentation:
- User Guide: `docs/source/usage/project/remote_execution.rst`
- Technical Details: `src/burai/ssh/README.md`

## Quick Reference

### Common Schedulers

| System | Submit Command | Status Command | Cancel Command |
|--------|---------------|----------------|----------------|
| PBS    | qsub script   | qstat          | qdel jobid     |
| SLURM  | sbatch script | squeue         | scancel jobid  |
| SGE    | qsub script   | qstat          | qdel jobid     |

### SSH Key Locations

- Private key: `~/.ssh/id_ed25519` or `~/.ssh/id_rsa`
- Public key: `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`
- Authorized keys (on server): `~/.ssh/authorized_keys`

### File Permissions

```bash
chmod 700 ~/.ssh                    # SSH directory
chmod 600 ~/.ssh/id_ed25519         # Private key
chmod 644 ~/.ssh/id_ed25519.pub     # Public key
chmod 600 ~/.ssh/authorized_keys    # On remote server
```
