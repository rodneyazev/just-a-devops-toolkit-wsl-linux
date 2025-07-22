# Makefile for DevOps tooling setup
# Version: 1.1.0

# Constants
NVM_VERSION := v0.40.3
DOJO_VERSION := 0.13.1
GPG_KEYRING := /usr/share/keyrings/cloud.google.gpg
GCLOUD_SOURCES_LIST := /etc/apt/sources.list.d/google-cloud-sdk.list
SSH_KEY_TYPE := ed25519
SSH_KEY_PATH := ~/.ssh/id_ed25519

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: all auto-update-upgrade install-gcloud install-aws install-terraform install-az install-oci \
        install-dojo install-gh install-ssh install-nvm install-ansible \
        install-all ssh-key-setup gh-login ansible-test help

all: install-all

install-all: auto-update-upgrade install-aws install-terraform install-gh install-ssh ssh-key-setup gh-login install-nvm
	@echo "$(GREEN)✅ All installations completed$(NC)"

auto-update-upgrade:
ifeq ($(SKIP_UPDATE),false)
	@echo "$(BLUE)🔄 Updating and upgrading system packages...$(NC)"
	@sudo apt-get update -qq && sudo apt-get upgrade -y
	@echo "$(GREEN)✅ System updated and upgraded$(NC)"
else
	@echo "$(YELLOW)⚠️ Skipping system update as requested$(NC)"
endif

install-gcloud:
	@if ! command -v gcloud >/dev/null 2>&1; then \
		echo "$(BLUE)📥 Downloading and installing Google Cloud SDK/CLI...$(NC)"; \
		sudo apt-get update -qq && sudo apt install -y apt-transport-https ca-certificates gnupg curl; \
		curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o $(GPG_KEYRING); \
		echo "deb [signed-by=$(GPG_KEYRING)] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee $(GCLOUD_SOURCES_LIST) >/dev/null; \
		sudo apt update -qq && sudo apt install -y google-cloud-cli; \
		echo "$(GREEN)✅ Google Cloud SDK/CLI installed$(NC)"; \
	else \
		echo "$(YELLOW)✅ Already installed: Google Cloud SDK/CLI$(NC)"; \
	fi

install-aws:
	@if ! command -v aws >/dev/null 2>&1; then \
		echo "$(BLUE)📥 Downloading and installing AWS SDK/CLI...$(NC)"; \
		sudo apt update -qq; \
		curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
		curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip.sig -o awscliv2.sig; \
		unzip -q awscliv2.zip; \
		sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update; \
		rm -rf awscliv2.zip awscliv2.sig aws; \
		echo "$(GREEN)✅ AWS SDK/CLI installed$(NC)"; \
	else \
		echo "$(YELLOW)✅ Already installed: AWS SDK/CLI$(NC)"; \
	fi

install-az:
	@if ! command -v az >/dev/null 2>&1; then \
		echo "$(BLUE)📥 Downloading and installing Azure SDK/CLI...$(NC)"; \
		sudo apt update -qq; \
		curl -fsSL https://aka.ms/InstallAzureCLIDeb | sudo bash; \
		echo "$(GREEN)✅ Azure SDK/CLI installed$(NC)"; \
	else \
		echo "$(YELLOW)✅ Already installed: Azure SDK/CLI$(NC)"; \
	fi

install-oci:
	@if ! command -v oci >/dev/null 2>&1; then \
		echo "$(BLUE)📥 Downloading and installing Oracle SDK/CLI...$(NC)"; \
		sudo apt update -qq; \
		bash -c "$$(curl -fsSL https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"; \
		echo "$(GREEN)✅ Oracle SDK/CLI installed$(NC)"; \
	else \
		echo "$(YELLOW)✅ Already installed: Oracle SDK/CLI$(NC)"; \
	fi

install-dojo:
	@if ! command -v dojo >/dev/null 2>&1; then \
		echo "$(BLUE)📥 Downloading and installing Dojo...$(NC)"; \
		sudo apt update -qq; \
		sudo curl -fsSL https://github.com/kudulab/dojo/releases/download/$(DOJO_VERSION)/dojo_linux_amd64 -o /usr/local/bin/dojo; \
		sudo chmod +x /usr/local/bin/dojo; \
		echo "$(GREEN)✅ Dojo installed$(NC)"; \
	else \
		echo "$(YELLOW)✅ Already installed: Dojo$(NC)"; \
	fi

install-gh:
	@if ! command -v gh >/dev/null 2>&1; then \
		echo "$(BLUE)📥 Downloading and installing GitHub CLI (gh)...$(NC)"; \
		sudo apt update -qq && sudo apt install -y gh; \
		echo "$(GREEN)✅ GitHub CLI (gh) installed$(NC)"; \
	else \
		echo "$(YELLOW)✅ Already installed: GitHub CLI (gh)$(NC)"; \
	fi

install-ssh:
	@if ! command -v ssh-keygen >/dev/null 2>&1; then \
		echo "$(BLUE)📥 Downloading and installing OpenSSH Client...$(NC)"; \
		sudo apt update -qq && sudo apt install -y openssh-client; \
		echo "$(GREEN)✅ OpenSSH Client installed$(NC)"; \
	else \
		echo "$(YELLOW)✅ Already installed: OpenSSH Client$(NC)"; \
	fi

install-nvm:
	@if ! command -v nvm >/dev/null 2>&1; then \
		echo "$(BLUE)📥 Downloading and installing NVM...$(NC)"; \
		curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$(NVM_VERSION)/install.sh | bash; \
		export NVM_DIR="$$([ -z "$${XDG_CONFIG_HOME-}" ] && printf %s "$${HOME}/.nvm" || printf %s "$${XDG_CONFIG_HOME}/nvm")"; \
		[ -s "$$NVM_DIR/nvm.sh" ] && \. "$$NVM_DIR/nvm.sh"; \
		echo "$(GREEN)✅ NVM installed$(NC)"; \
		echo "$(YELLOW)⚠️ Please restart the shell or run the following command to enable nvm: $(GREEN)source ~/.bashrc$(NC)"; \
		echo "$(YELLOW)⚠️ Run $(GREEN)nvm ls-remote$(NC)$(YELLOW)command to see the full list of node versions.$(NC)"; \
		echo "$(YELLOW)⚠️ Upgrade node version: $(GREEN)nvm install <version_number_only>$(NC)"; \
	else \
		echo "$(YELLOW)✅ Already installed: NVM$(NC)"; \
	fi
	
install-ansible: .ansible.cfg .ansible-hosts
	@if ! command -v ansible >/dev/null 2>&1; then \
		echo "$(BLUE)📥 Downloading and installing Ansible...$(NC)"; \
		sudo apt update -qq && sudo apt install -y software-properties-common ansible; \
		echo "$(GREEN)✅ Ansible installed$(NC)"; \
	else \
		echo "$(YELLOW)✅ Already installed: Ansible$(NC)"; \
	fi

install-terraform: 
	@if ! command -v terraform >/dev/null 2>&1; then \
		echo "$(BLUE)📥 Downloading and installing Terraform...$(NC)"; \
		sudo apt-get update && sudo apt-get install -y gnupg software-properties-common; \
		wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null; \
		gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint --quiet; \
		echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null; \
		sudo apt update; \
		sudo apt-get install -y terraform; \
		terraform -install-autocomplete; \
		echo "$(GREEN)✅ Terraform installed$(NC)"; \
	else \
		echo "$(YELLOW)✅ Already installed: Terraform$(NC)"; \
	fi

.ansible.cfg:
	@echo "$(BLUE)🛠 Creating Ansible config file...$(NC)"
	@echo "[defaults]" > $@
	@echo "inventory = ~/.ansible-hosts" >> $@
	@echo "host_key_checking = False" >> $@
	@echo "$(GREEN)✅ Created $@$(NC)"

.ansible-hosts:
	@echo "$(BLUE)🛠 Creating Ansible inventory file...$(NC)"
	@echo "localhost ansible_connection=local" > $@
	@echo "$(GREEN)✅ Created $@$(NC)"

ansible-test.yml:
	@echo "$(BLUE)🛠 Creating Ansible test playbook...$(NC)"
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
	@echo "$(GREEN)✅ Created $@$(NC)"

ansible-test: install-ansible ansible-test.yml
	@echo "$(BLUE)🚀 Testing Ansible setup...$(NC)"
	@ansible-playbook ansible-test.yml
	@rm -f ansible-test.yml
	@echo "$(GREEN)✅ Ansible test completed successfully!$(NC)"

ssh-key-setup: install-ssh
	@echo "$(BLUE)🔑 Generating SSH key...$(NC)"
	@if [ ! -f $(SSH_KEY_PATH) ]; then \
		echo -e "$(YELLOW)Enter your email for SSH key: $(NC)\c"; \
		read EMAIL; \
		ssh-keygen -t $(SSH_KEY_TYPE) -C "$$EMAIL" -f $(SSH_KEY_PATH) -N ""; \
		echo "$(GREEN)✅ SSH key generated at $(SSH_KEY_PATH)$(NC)"; \
		echo "$(YELLOW)Public key:$(NC)"; \
		cat $(SSH_KEY_PATH).pub; \
	else \
		echo "$(YELLOW)⚠️ SSH key already exists at $(SSH_KEY_PATH)$(NC)"; \
	fi

gh-login: install-gh
	@echo "$(BLUE)🔐 Logging into GitHub...$(NC)"; \
	gh auth login --web -h github.com | grep 'user code' | awk '{print $$NF}'; \
	gh auth status
	@echo "$(GREEN)✅ Logged in to GitHub$(NC)"

help:
	@echo "$(BLUE)----------------------------------------------------------------------$(NC)"
	@echo "$(GREEN)DevOps Tooling Setup - Makefile$(NC)"
	@echo "$(BLUE)----------------------------------------------------------------------$(NC)"
	@echo "$(YELLOW)Available targets:$(NC)"
	@echo "  $(GREEN)all$(NC)                  - Alias for install-all"
	@echo "  $(GREEN)auto-update-upgrade$(NC)  - Update system packages (SKIP_UPDATE=false, to skip)"
	@echo "  $(GREEN)install-all$(NC)          - Install all tools (default=AWS CLI, Terraform, GH && Login, SSH && Key-Setup, NVM)"
	@echo "  $(GREEN)install-gcloud$(NC)       - Install Google Cloud SDK"
	@echo "  $(GREEN)install-aws$(NC)          - Install AWS CLI"
	@echo "  $(GREEN)install-az$(NC)           - Install Azure CLI"
	@echo "  $(GREEN)install-oci$(NC)          - Install Oracle Cloud CLI"
	@echo "  $(GREEN)install-terraform$(NC)    - Install Terraform"
	@echo "  $(GREEN)install-ssh$(NC)          - Install OpenSSH Client"
	@echo "  $(GREEN)install-gh$(NC)           - Install GitHub CLI"
	@echo "  $(GREEN)install-nvm$(NC)          - Install Node Version Manager {NPM and Node, up-to-date}"
	@echo "  $(GREEN)install-ansible$(NC)      - Install Ansible and generate config files"
	@echo "  $(GREEN)install-dojo$(NC)         - Install Dojo tool"
	@echo "  $(GREEN)ansible-test$(NC)         - Test Ansible Installation"
	@echo "  $(GREEN)ssh-key-setup$(NC)        - Generate SSH key"
	@echo "  $(GREEN)gh-login$(NC)             - Login to GitHub"
	@echo "  $(GREEN)help$(NC)                 - Show this help"
	@echo "$(BLUE)----------------------------------------------------------------------$(NC)"
	@echo "$(YELLOW)Note:$(NC)Before installation ensure system has curl, wget, make, unzip installed."
	@echo " "
	@echo "$(GREEN)sudo apt update && sudo apt upgrade -y && sudo apt install curl wget make unzip -y$(NC)"
	@echo " "
	@echo "$(BLUE)----------------------------------------------------------------------$(NC)"
