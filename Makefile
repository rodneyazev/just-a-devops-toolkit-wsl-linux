   # =======================================
# Makefile for DevOps tooling setup
# Version: 1.1.1
# =======================================
SHELL = /bin/bash

# Debug/Quiet Configuration
DEBUG ?= false
ifeq ($(DEBUG),true)
    QUIET =
    VERBOSE_FLAG = -v
    APT_QUIET = 
    CURL_QUIET = -v
    DEBUG_INFO = @echo "$(COLOR_CYAN)[DEBUG]$(COLOR_RESET)"
else
    QUIET = >/dev/null 2>&1
    VERBOSE_FLAG = 
    APT_QUIET = -qq
    CURL_QUIET = -s
    DEBUG_INFO = @true
endif

# Build Information
BUILD_DATE := $(shell date '+%Y-%m-%d %H:%M:%S')
BUILD_USER := $(shell whoami)
BUILD_HOST := $(shell hostname)

# Constants
NVM_VERSION = v0.40.3
DOJO_VERSION = 0.13.1
GPG_KEYRING = /usr/share/keyrings/cloud.google.gpg
GCLOUD_SOURCES_LIST = /etc/apt/sources.list.d/google-cloud-sdk.list
SSH_KEY_TYPE = ed25519
SSH_KEY_PATH = ~/.ssh/id_ed25519

# Colors ANSI
COLOR_RED = \033[0;31m
COLOR_GREEN = \033[0;32m
COLOR_YELLOW = \033[0;33m
COLOR_CYAN = \033[1;36m
COLOR_MAGENTA = \033[1;35m
COLOR_BLUE = \033[0;34m
COLOR_LIGHTBLUE = \033[1;34m
COLOR_WHITE = \033[1;37m
COLOR_DIM = \033[2m
COLOR_UNDERLINE = \033[4m
COLOR_UNDERLINE_DIM = \033[4;2m
COLOR_UNDERLINE_BOLD = \033[4;1m
COLOR_REVERSE = \033[7m
COLOR_ITALIC = \033[3m
COLOR_BRIGHT = \033[1m
COLOR_FAINT = \033[2m
COLOR_BOLD = \033[1m
NO_COLOR = \033[0m

# Flags
COLOR_RESET = $(NO_COLOR)
COLOR_BANNER = $(COLOR_CYAN)
COLOR_SECTION = $(COLOR_MAGENTA)
COLOR_DONE = $(COLOR_GREEN)
COLOR_WARN = $(COLOR_YELLOW)
COLOR_LOADING = $(COLOR_BLUE)

# Emojis
DOT_EMOJI = ㆍ
KEY_EMOJI = 🔑
FILE_EMOJI = 📄
INFO_EMOJI = ℹ️
CHECK_EMOJI = ✔ 
ERROR_EMOJI = ❌
FINGER_EMOJI = 👉 
ROCKET_EMOJI = 🚀
SUCCESS_EMOJI = ✅️
WARNING_EMOJI = ⚠️
PADLOCK_EMOJI = 🔒
CREATING_EMOJI = 🛠
UPDATING_EMOJI = 🔄
DIRECTION_EMOJI = ➡️
DOWNLOADING_EMOJI = 📥

# Make

# Targets
.PHONY: all minimum_required update-system install-gcloud install-aws install-azure install-oci install-terraform install-dojo install-gh \
        install-ansible install-nvm ansible-test \
		ssh-key-config gh-login-config \
        help banner show-config check-prereqs clean

# Default targets
all: minimum_required update-system install-aws install-azure install-gcloud install-oci install-terraform install-dojo install-gh \
    install-ansible install-nvm

# My personal targets
# votc: minimum_required update-system install-aws install-terraform install-gh install-ansible install-nvm

# Utility Functions
define log_info
	@echo -e "$(INFO_EMOJI) $(COLOR_INFO)$(1)$(COLOR_RESET)"
endef

define log_success
	@echo -e "$(SUCCESS_EMOJI) $(COLOR_DONE)$(1)$(COLOR_RESET)"
endef

define log_warning
	@echo -e "$(WARNING_EMOJI) $(COLOR_WARN)$(1)$(COLOR_RESET)"
endef

define log_error
	@echo -e "$(ERROR_EMOJI) $(COLOR_ERROR)$(1)$(COLOR_RESET)"
endef

define log_debug
	@if [ "$(DEBUG)" = "true" ]; then \
		echo -e "$(DEBUG_EMOJI) $(COLOR_DIM)[DEBUG] $(1)$(COLOR_RESET)"; \
	fi
endef

# Check prerequisites
check-prereqs:
	$(call log_info,Checking system prerequisites...)
	$(call log_debug,Checking if running as non-root user)
	@if [ "$(shell id -u)" = "0" ]; then \
		$(call log_error,Please do not run as root user); \
		exit 1; \
	fi
	$(call log_debug,Checking sudo access)
	@if ! sudo -n true 2>/dev/null; then \
		$(call log_warning,Sudo access required. You may be prompted for password); \
	fi
ifeq ($(CHECK_INTERNET),true)
	$(call log_debug,Checking internet connectivity)
	@if ! ping -c 1 -W 3 8.8.8.8 $(QUIET); then \
		$(call log_error,No internet connectivity detected); \
		exit 1; \
	fi
endif
	$(call log_success,Prerequisites check completed)

banner:
	@echo ""
	@echo -e "$(COLOR_BANNER)╔══════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BANNER)║                   DevOps Tooling Setup                       ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BANNER)║                     Version 1.2.0                            ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BANNER)╚══════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""

# Show current configuration
show-config:
	@echo -e "$(COLOR_SECTION)Current Configuration:$(COLOR_RESET)"
	@echo -e "  NVM Version:    $(NVM_VERSION)"
	@echo -e "  Dojo Version:   $(DOJO_VERSION)"
	@echo -e "  SSH Key Type:   $(SSH_KEY_TYPE)"
	@echo -e "  SSH Key Path:   $(SSH_KEY_PATH)"
	@echo -e "  GPG Keyring:    $(GPG_KEYRING)"
	@echo -e "  GCloud Sources: $(GCLOUD_SOURCES_LIST)"
	@echo ""
	@echo -e "$(COLOR_SECTION)Runtime Flags:$(COLOR_RESET)"
	@echo -e "  DEBUG: $(DEBUG)"
	@echo -e "  SKIP_UPDATE: $(SKIP_UPDATE)"
	@echo -e "  FORCE_INSTALL: $(FORCE_INSTALL)"
	@echo -e "  CHECK_INTERNET: $(CHECK_INTERNET)"

# Help target
help: banner
	@echo -e "$(COLOR_BANNER)DevOps Tooling Setup Makefile$(COLOR_RESET)"
	@echo ""
	@echo -e "$(COLOR_SECTION)Usage:$(COLOR_RESET)"
	@echo "  make [target] [options]"
	@echo ""
	@echo -e "$(COLOR_SECTION)Main Targets:$(COLOR_RESET)"
	@echo "     all                 - Run all installation tasks (default)"
	@echo "     minimum_required    - Install minimum required packages"
	@echo "     update-system       - Update and upgrade system packages"
	@echo "     install-gcloud      - Install Google Cloud SDK/CLI"
	@echo "     install-aws         - Install AWS Cloud SDK/CLI"
	@echo "     install-azure       - Install Azure Cloud SDK/CLI"
	@echo "     install-oci         - Install Oracle Cloud SDK/CLI"
	@echo "     install-terraform   - Install Terraform"
	@echo "     install-dojo        - Install Dojo"
	@echo "     install-gh          - Install GH Github CLI"
	@echo "     install-ansible     - Install Ansible"
	@echo "     install-nvm         - Install NVM (Node Version Manager)"
	@echo "     ansible-test        - Run Ansible test playbook"
	@echo "     ssh-key-config      - Generate SSH key for GitHub/GitLab"
	@echo "     gh-login-config     - Configure GH GitHub CLI login"
	@echo "     check-prereqs       - Check system prerequisites"
	@echo "     clean               - Clean temporary files and caches"
	@echo "     show-config         - Display current configuration"
	@echo "     help                - Show this help message"
	@echo ""
	@echo -e "$(COLOR_SECTION)Options:$(COLOR_RESET)"
	@echo "     DEBUG=true          - Enable debug/verbose output"
	@echo "     SKIP_UPDATE=true    - Skip system update (default: false)"
	@echo "     FORCE_INSTALL=true  - Force reinstallation (default: false)"
	@echo "     CHECK_INTERNET=true - Check internet connectivity (default: true)"
	@echo ""
	@echo -e "$(COLOR_SECTION)Examples:$(COLOR_RESET)"
	@echo "     make DEBUG=true                 # Run with debug output"
	@echo "     make install-gcloud DEBUG=true  # Install gcloud with debug"
	@echo "     make SKIP_UPDATE=true           # Skip system updates"

# Clean up temporary files and caches
clean:
	$(call log_info,Cleaning up temporary files and caches ...)
	$(call log_debug,Cleaning apt cache)
	@sudo apt autoremove -y $(QUIET) || true
	@sudo apt autoclean $(QUIET) || true
	$(call log_success,Cleanup completed.)

update-system:
ifeq ($(SKIP_UPDATE),false)
	@echo -n "$(UPDATING_EMOJI) Updating repositories ... "
	@sudo apt update $(QUIET)
	@sleep 1
	@printf "\r$(CHECK_EMOJI) Updating repositories ... Done\n"

	@echo -n "$(ROCKET_EMOJI) Upgrading system ... "
	@sudo apt upgrade -y $(QUIET)
	@sleep 1
	@printf "\r$(SUCCESS_EMOJI) Upgrading system ... Done\n"
else	
	@echo -e "$(SUCCESS_EMOJI)$(COLOR_DONE) System already updated.$(COLOR_RESET)"
endif

minimum_required: update-system
	@if command -v wget $(QUIET); then \
		echo -e "$(SUCCESS_EMOJI)$(COLOR_DONE) Minimum Required Packages already installed.$(COLOR_RESET)"; \
	else \
		message=" Installing Minimum Required Packages "; \
    	spinner_func() { \
        	i=0; \
        	local spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"); \
			local dots=(".  " ".  " ".. " ".. " "..." "..."); \
        	while kill -0 $$1 2>/dev/null; do \
            	printf "\r\033[1;34m%s\033[0m %s\033[1;34m%s\033[0m" "$${spinner[i % $${#spinner[@]}]}" "$$message" "$${dots[i % $${#dots[@]}]}"; \
				i=$$((i+1)); \
				sleep 0.2; \
        	done; \
    	}; \
    	(sudo apt install curl wget make unzip ssh git apt-transport-https ca-certificates gnupg software-properties-common -y $(QUIET)) & \
    	CMD_PID=$$!; \
    	spinner_func $$CMD_PID; \
    	wait $$CMD_PID; \
    	printf "\r$(CHECK_EMOJI)$${message}$(COLOR_LIGHTBLUE)...$(COLOR_RESET) $(COLOR_GREEN)$(COLOR_BOLD)Done$(COLOR_RESET)\n"; \
	fi

install-gcloud: minimum_required
	@if command -v gcloud $(QUIET); then \
		echo -n "$(SUCCESS_EMOJI) Google Cloud SDK/CLI already installed $(DIRECTION_EMOJI) "; \
		gcloud --version | head -n 1; \
	else \
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o $(GPG_KEYRING) --yes && \
        echo "deb [signed-by=$(GPG_KEYRING)] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee $(GCLOUD_SOURCES_LIST) $(QUIET); \
        message=" Installing Google Cloud SDK "; \
        spinner_func() { \
            i=0; \
            local spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"); \
			local dots=(".  " ".  " ".. " ".. " "..." "..."); \
            while kill -0 $$1 2>/dev/null; do \
                printf "\r\033[1;34m%s\033[0m %s\033[1;34m%s\033[0m" "$${spinner[i % $${#spinner[@]}]}" "$$message" "$${dots[i % $${#dots[@]}]}"; \
				i=$$((i+1)); \
				sleep 0.2; \
            done; \
        }; \
        (sudo apt update $(QUIET) && sudo apt install -y google-cloud-cli $(QUIET)) & \
        CMD_PID=$$!; \
        spinner_func $$CMD_PID; \
        wait $$CMD_PID; \
        printf "\r$(CHECK_EMOJI)$${message}$(COLOR_LIGHTBLUE)...$(COLOR_RESET) $(COLOR_GREEN)$(COLOR_BOLD)Done$(COLOR_RESET)\n"; \
	fi

install-aws: minimum_required
	@if command -v aws $(QUIET); then \
		echo -n "$(SUCCESS_EMOJI) AWS SDK/CLI already installed $(DIRECTION_EMOJI) aws/cli "; \
		aws --version | cut -d' ' -f1 | cut -d'/' -f2; \
	else \
        spinner_func() { \
            i=0; \
            local spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"); \
            local dots=(".  " ".  " ".. " ".. " "..." "..."); \
            message=" Installing AWS SDK/CLI "; \
            while kill -0 $$1 2>/dev/null; do \
            printf "\r\033[1;34m%s\033[0m %s\033[1;34m%s\033[0m" "$${spinner[i % $${#spinner[@]}]}" "$$message" "$${dots[i % $${#dots[@]}]}"; \
                i=$$((i+1)); \
				sleep 0.2; \
            done; \
        }; \
        ( \
            sudo apt update $(QUIET); \
		    curl $(CURL_QUIET) -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" $(QUIET); \
		    unzip -q awscliv2.zip $(QUIET); \
		    sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update $(QUIET); \
		    rm -rf awscliv2.zip aws \
		) & \
        CMD_PID=$$!; \
        spinner_func $$CMD_PID; \
        wait $$CMD_PID; \
        printf "\r$(CHECK_EMOJI)$${message}$(COLOR_LIGHTBLUE)...$(COLOR_RESET) $(COLOR_GREEN)$(COLOR_BOLD)Done$(COLOR_RESET)\n"; \
	fi

install-azure: minimum_required
	@if command -v az $(QUIET); then \
		echo -n "$(SUCCESS_EMOJI) Azure SDK/CLI already installed $(DIRECTION_EMOJI) "; \
		az --version | awk '/azure-cli/ {print $2}' | tr -s ' '; \
	else \
        spinner_func() { \
            i=0; \
            local spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"); \
            local dots=(".  " ".  " ".. " ".. " "..." "..."); \
            message=" Installing Azure SDK/CLI "; \
            while kill -0 $$1 2>/dev/null; do \
            printf "\r\033[1;34m%s\033[0m %s\033[1;34m%s\033[0m" "$${spinner[i % $${#spinner[@]}]}" "$$message" "$${dots[i % $${#dots[@]}]}"; \
                i=$$((i+1)); \
				sleep 0.2; \
            done; \
        }; \
        ( sudo apt update $(QUIET) && curl -fsSL https://aka.ms/InstallAzureCLIDeb | sudo bash $(QUIET)) & \
        CMD_PID=$$!; \
        spinner_func $$CMD_PID; \
        wait $$CMD_PID; \
        printf "\r$(CHECK_EMOJI)$${message}$(COLOR_LIGHTBLUE)...$(COLOR_RESET) $(COLOR_GREEN)$(COLOR_BOLD)Done$(COLOR_RESET)\n"; \
	fi
    
install-oci: minimum_required
	@if command -v oci $(QUIET) || [ -f ~/.local/bin/oci ] $(QUIET); then \
		echo -n "$(SUCCESS_EMOJI) Oracle SDK/CLI already installed $(DIRECTION_EMOJI) "; \
		~/.local/bin/oci --version; \
		echo -e "$(DOT_EMOJI) Restart your shell or type $(COLOR_YELLOW)source ~/.bashrc$(COLOR_RESET) to enable OCI."; \
	else \
        spinner_func() { \
            i=0; \
            local spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"); \
            local dots=(".  " ".  " ".. " ".. " "..." "..."); \
            message=" Installing OCI SDK/CLI "; \
            while kill -0 $$1 2>/dev/null; do \
            printf "\r\033[1;34m%s\033[0m %s\033[1;34m%s\033[0m" "$${spinner[i % $${#spinner[@]}]}" "$$message" "$${dots[i % $${#dots[@]}]}"; \
                i=$$((i+1)); \
				sleep 0.2; \
            done; \
        }; \
        ( \
            sudo apt update $(QUIET); \
           	curl -L -o install-oci-cli.sh https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh $(QUIET); \
			chmod +x install-oci-cli.sh; \
			./install-oci-cli.sh --accept-all-defaults --install-dir ~/.local/lib/oracle-cli --exec-dir ~/.local/bin --script-dir ~/.local/bin $(QUIET); \
			rm -f install-oci-cli.sh; \
			echo 'export PATH=$$PATH:/usr/local/lib/oracle-cli/bin' >> $$HOME/.bashrc; \
			echo 'export PATH=$$PATH:/usr/local/lib/oracle-cli/bin' >> $$HOME/.profile; \
			. $$HOME/.bashrc; \
			. $$HOME/.profile \
			) & \
        CMD_PID=$$!; \
        spinner_func $$CMD_PID; \
        wait $$CMD_PID; \
        printf "\r$(CHECK_EMOJI)$${message}$(COLOR_LIGHTBLUE)...$(COLOR_RESET) $(COLOR_GREEN)$(COLOR_BOLD)Done$(COLOR_RESET)\n"; \
		echo -e "$(DOT_EMOJI) Restart your shell or type $(COLOR_YELLOW)source ~/.bashrc$(COLOR_RESET) to enable OCI."; \
	fi

install-dojo: minimum_required
	@if command -v dojo $(QUIET); then \
		echo -n "$(SUCCESS_EMOJI) Dojo already installed $(DIRECTION_EMOJI) "; \
		dojo --version | head -n 1; \
	else \
        spinner_func() { \
            i=0; \
            local spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"); \
            local dots=(".  " ".  " ".. " ".. " "..." "..."); \
            message=" Installing Dojo "; \
            while kill -0 $$1 2>/dev/null; do \
            printf "\r\033[1;34m%s\033[0m %s\033[1;34m%s\033[0m" "$${spinner[i % $${#spinner[@]}]}" "$$message" "$${dots[i % $${#dots[@]}]}"; \
                i=$$((i+1)); \
				sleep 0.2; \
            done; \
        }; \
        (   \
			sudo apt update $(QUIET); \
            curl -fsSL https://github.com/kudulab/dojo/releases/download/${DOJO_VERSION}/dojo_linux_amd64 -o /tmp/dojo $(QUIET); \
            sudo mv /tmp/dojo /usr/local/bin/dojo $(QUIET); \
            sudo chmod +x /usr/local/bin/dojo $(QUIET) \
        ) & \
        CMD_PID=$$!; \
        spinner_func $$CMD_PID; \
        wait $$CMD_PID; \
        printf "\r$(CHECK_EMOJI)$${message}$(COLOR_LIGHTBLUE)...$(COLOR_RESET) $(COLOR_GREEN)$(COLOR_BOLD)Done$(COLOR_RESET)\n"; \
	fi

install-gh: minimum_required
	@if command -v gh $(QUIET); then \
		echo -n "$(SUCCESS_EMOJI) GH GitHub CLI already installed $(DIRECTION_EMOJI) "; \
		gh --version | head -n 1; \
	else \
        spinner_func() { \
            i=0; \
            local spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"); \
            local dots=(".  " ".  " ".. " ".. " "..." "..."); \
            message=" Installing GH GitHub CLI "; \
            while kill -0 $$1 2>/dev/null; do \
            printf "\r\033[1;34m%s\033[0m %s\033[1;34m%s\033[0m" "$${spinner[i % $${#spinner[@]}]}" "$$message" "$${dots[i % $${#dots[@]}]}"; \
                i=$$((i+1)); \
				sleep 0.2; \
            done; \
        }; \
        (sudo apt update $(QUIET) && sudo apt install -y gh $(QUIET)) & \
        CMD_PID=$$!; \
        spinner_func $$CMD_PID; \
        wait $$CMD_PID; \
        printf "\r$(CHECK_EMOJI)$${message}$(COLOR_LIGHTBLUE)...$(COLOR_RESET) $(COLOR_GREEN)$(COLOR_BOLD)Done$(COLOR_RESET)\n"; \
	fi

install-nvm: minimum_required
	@if [ -s "$$HOME/.nvm/nvm.sh" ] || [ -s "$$NVM_DIR/nvm.sh" ]; then \
		echo "$(SUCCESS_EMOJI) NVM already installed." ; \
        echo -e "$(DOT_EMOJI) Restart your shell or type $(COLOR_YELLOW)source ~/.bashrc$(COLOR_RESET) to enable NVM."; \
		echo -e "$(DOT_EMOJI) Type $(COLOR_YELLOW)nvm ls-remote$(COLOR_RESET) to see the full list of node versions."; \
		echo -e "$(DOT_EMOJI) Run $(COLOR_YELLOW)nvm install $(COLOR_GREEN)<version_number_only>$(COLOR_RESET) to install or upgrade node version."; \
	else \
        spinner_func() { \
            i=0; \
            local spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"); \
            local dots=(".  " ".  " ".. " ".. " "..." "..."); \
            message=" Installing NVM "; \
            while kill -0 $$1 2>/dev/null; do \
            printf "\r\033[1;34m%s\033[0m %s\033[1;34m%s\033[0m" "$${spinner[i % $${#spinner[@]}]}" "$$message" "$${dots[i % $${#dots[@]}]}"; \
                i=$$((i+1)); \
				sleep 0.2; \
            done; \
        }; \
        (   sudo apt update $(QUIET); \
            curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$(NVM_VERSION)/install.sh | bash $(QUIET); \
            export NVM_DIR="$$HOME/.nvm"; \
            [ -s "$$NVM_DIR/nvm.sh" ] && \. "$$NVM_DIR/nvm.sh"; \
            [ -s "$$NVM_DIR/bash_completion" ] && \. "$$NVM_DIR/bash_completion"; \
            echo 'export NVM_DIR="$$HOME/.nvm"' >> $$HOME/.bashrc; \
            echo '[ -s "$$NVM_DIR/nvm.sh" ] && \. "$$NVM_DIR/nvm.sh"' >> $$HOME/.bashrc; \
            echo '[ -s "$$NVM_DIR/bash_completion" ] && \. "$$NVM_DIR/bash_completion"' >> $$HOME/.bashrc; \
            . $$HOME/.bashrc \
        ) & \
        CMD_PID=$$!; \
        spinner_func $$CMD_PID; \
        wait $$CMD_PID; \
        printf "\r$(CHECK_EMOJI)$${message}$(COLOR_LIGHTBLUE)...$(COLOR_RESET) $(COLOR_GREEN)$(COLOR_BOLD)Done$(COLOR_RESET)\n"; \
        echo -e "$(DOT_EMOJI) Restart your shell or type $(COLOR_YELLOW)source ~/.bashrc$(COLOR_RESET) to enable NVM."; \
		echo -e "$(DOT_EMOJI) Type $(COLOR_YELLOW)nvm ls-remote$(COLOR_RESET) to see the full list of node versions."; \
		echo -e "$(DOT_EMOJI) Run $(COLOR_YELLOW)nvm install <version_number_only>$(COLOR_RESET) to install or upgrade node version."; \
	fi

install-ansible: minimum_required .ansible.cfg .ansible-hosts
	@if command -v ansible $(QUIET); then \
		echo -n "$(SUCCESS_EMOJI) Ansible already installed $(DIRECTION_EMOJI) "; \
		ansible --version | head -n 1; \
		echo -e "$(DOT_EMOJI) Run $(COLOR_YELLOW)make ansible-test$(COLOR_RESET) to test ansible"; \
	else \
        spinner_func() { \
            i=0; \
            local spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"); \
            local dots=(".  " ".  " ".. " ".. " "..." "..."); \
            message=" Installing Ansible "; \
            while kill -0 $$1 2>/dev/null; do \
            printf "\r\033[1;34m%s\033[0m %s\033[1;34m%s\033[0m" "$${spinner[i % $${#spinner[@]}]}" "$$message" "$${dots[i % $${#dots[@]}]}"; \
                i=$$((i+1)); \
				sleep 0.2; \
            done; \
        }; \
        (sudo apt update $(QUIET) && sudo apt install ansible -y $(QUIET)) & \
        CMD_PID=$$!; \
        spinner_func $$CMD_PID; \
        wait $$CMD_PID; \
        printf "\r$(CHECK_EMOJI)$${message}$(COLOR_LIGHTBLUE)...$(COLOR_RESET) $(COLOR_GREEN)$(COLOR_BOLD)Done$(COLOR_RESET)\n"; \
	fi

.ansible.cfg:
	@echo "[defaults]" > $@
	@echo "inventory = ~/.ansible-hosts" >> $@
	@echo "host_key_checking = False" >> $@
	@echo -e "$(FILE_EMOJI) .ansible.cfg file created."

.ansible-hosts:
	@echo "localhost ansible_connection=local" > $@
	@echo -e "$(FILE_EMOJI) .ansible-hosts file created."

ansible-test.yml:
	@echo "---" > $@
	@echo "- name: Test Ansible Setup" >> $@
	@echo "  hosts: localhost" >> $@
	@echo "  connection: local" >> $@
	@echo "  gather_facts: no" >> $@
	@echo "  tasks:" >> $@
	@echo "    - name: Verify Ansible is working" >> $@
	@echo "      debug:" >> $@
	@echo "        msg: \"Ansible test successful!\"" >> $@
	@echo "    - name: Check Python availability" >> $@
	@echo "      raw: which python3 || which python" >> $@
	@echo "      register: python_path" >> $@
	@echo "      changed_when: false" >> $@
	@echo "    - name: Show Python path" >> $@
	@echo "      debug:" >> $@
	@echo "        var: python_path.stdout" >> $@
	@echo -e "$(FILE_EMOJI) ansible-test.yml file created."

ansible-test: ansible-test.yml
	@echo "$(ROCKET_EMOJI) Testing ansible ..."
	@ansible-playbook ansible-test.yml
	@rm -f ansible-test.yml
	@echo -e "$(SUCCESS_EMOJI) Ansible test completed successfully!"

install-terraform: minimum_required
	@if command -v terraform $(QUIET); then \
		echo -n "$(SUCCESS_EMOJI) Terraform already installed $(DIRECTION_EMOJI) "; \
		terraform -v | head -n 1; \
	else \
        spinner_func() { \
            i=0; \
            local spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"); \
            local dots=(".  " ".  " ".. " ".. " "..." "..."); \
            message=" Installing Terraform "; \
            while kill -0 $$1 2>/dev/null; do \
            printf "\r\033[1;34m%s\033[0m %s\033[1;34m%s\033[0m" "$${spinner[i % $${#spinner[@]}]}" "$$message" "$${dots[i % $${#dots[@]}]}"; \
                i=$$((i+1)); \
				sleep 0.2; \
            done; \
        }; \
        ( \
            sudo apt-get update $(QUIET); \
			curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg --yes && \
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main" | sudo tee /etc/apt/sources.list.d/hashicorp.list $(QUIET) && \
            sudo apt-get update $(QUIET) && sudo apt-get install -y terraform $(QUIET); \
		) & \
        CMD_PID=$$!; \
        spinner_func $$CMD_PID; \
        wait $$CMD_PID; \
        printf "\r$(CHECK_EMOJI)$${message}$(COLOR_LIGHTBLUE)...$(COLOR_RESET) $(COLOR_GREEN)$(COLOR_BOLD)Done$(COLOR_RESET)\n"; \
	fi

ssh-key-config: minimum_required
	@echo -e "$(COLOR_LIGHTBLUE)$(KEY_EMOJI) Generating SSH key...$(COLOR_RESET)"
	@if [ ! -f $(SSH_KEY_PATH) ]; then \
		echo -e "$(COLOR_YELLOW)Enter your email for SSH key: $(COLOR_RESET)\c"; \
		read EMAIL; \
		ssh-keygen -t $(SSH_KEY_TYPE) -C "$$EMAIL" -f $(SSH_KEY_PATH) -N ""; \
		echo -e "$(COLOR_GREEN)$(COLOR_DONE) SSH key generated at $(SSH_KEY_PATH)$(COLOR_RESET)"; \
		echo -en "$(COLOR_YELLOW)Public key:$(COLOR_RESET) "; \
		cat $(SSH_KEY_PATH).pub; \
	else \
		echo -e "$(COLOR_YELLOW)$(INFO_EMOJI) SSH key already exists at $(SSH_KEY_PATH)$(COLOR_RESET)"; \
	fi

gh-login-config: 
	@echo -e "$(COLOR_LIGHTBLUE)$(PADLOCK_EMOJI) Logging into GitHub...$(COLOR_RESET)"; \
	gh auth login --web -h github.com | grep 'user code' | awk '{print $$NF}'; \
	gh auth status
	@echo -e "$(COLOR_GREEN)$(COLOR_DONE) Logged in to GitHub$(COLOR_RESET)"