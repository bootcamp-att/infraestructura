# ============================================================
# Terraform
# ============================================================

# Directorios locales de trabajo
.terraform/
**/.terraform/

# Archivos de estado
*.tfstate
*.tfstate.*

# Información temporal de bloqueo
.terraform.tfstate.lock.info

# Planes guardados: pueden contener información sensible
*.tfplan
*.plan
tfplan
plan.out

# Registros de errores
crash.log
crash.*.log

# Variables locales: pueden contener credenciales y secretos
*.tfvars
*.tfvars.json

# Archivos de sobrescritura locales
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Configuración local de Terraform CLI
.terraformrc
terraform.rc

# IMPORTANTE:
# No ignorar .terraform.lock.hcl.
# Debe versionarse para fijar las versiones de los proveedores.


# ============================================================
# AWS
# ============================================================

# Credenciales locales de AWS
.aws/
.aws-sam/

# Archivos de configuración locales con posibles secretos
.env
.env.*
!.env.example


# ============================================================
# Claves privadas y certificados locales
# ============================================================

# Claves SSH privadas generadas localmente
id_rsa
id_ed25519
*.pem

# Archivos de claves privadas locales
*.key

# No incluir aquí certificados públicos que deban versionarse.


# ============================================================
# Ansible
# ============================================================

# Inventario generado por Terraform
/ansible/inventory.ini

# Archivos locales para introducir contraseñas de Ansible Vault
/ansible/vault-password-file
/ansible/.vault_pass

# Archivos de respaldo y temporales
*.retry
*.swp
*.swo
*~

# No ignorar indiscriminadamente archivos YAML cifrados con Vault.
# Los archivos cifrados que formen parte del proyecto pueden
# versionarse; las contraseñas de descifrado deben mantenerse fuera.


# ============================================================
# Editores y sistema operativo
# ============================================================

# Visual Studio Code: configuración personal
.vscode/

# IntelliJ IDEA
.idea/

# Archivos temporales del sistema operativo
.DS_Store
Thumbs.db