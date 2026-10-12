import csv
import re
import secrets
import string

# Configuración de archivos
INPUT_FILE = "correos_alumnos.txt"      # Archivo de entrada solo con correos
OUTPUT_FILE = "usuarios_bootcamp.csv"   # Archivo CSV generado para Ansible

def generar_password(longitud=12):
    """Genera una contraseña aleatoria segura con letras, números y símbolos."""
    caracteres = string.ascii_letters + string.digits + "!@#$%&*"
    return ''.join(secrets.choice(caracteres) for _ in range(longitud))

def procesar_correo(correo):
    """Extrae el username y genera un displayName legible a partir del email."""
    correo = correo.strip()
    if not correo or "@" not in correo:
        return None

    # Tomar la parte antes del @
    local_part = correo.split("@")[0]
    
    # Username limpio en minúsculas (reemplazar puntos, guiones, etc.)
    username = re.sub(r'[^a-zA-Z0-9]', '', local_part).lower()
    
    # Generar Display Name reemplazando separadores por espacios y capitalizando cada palabra
    partes_nombre = re.split(r'[\._\-\+]', local_part)
    display_name = ' '.join(word.capitalize() for word in partes_nombre if word)

    password = generar_password()

    return {
        "username": username,
        "email": correo,
        "displayName": display_name,
        "password": password
    }

def main():
    try:
        with open(INPUT_FILE, mode='r', encoding='utf-8') as infile:
            lineas = infile.readlines()
    except FileNotFoundError:
        print(f"❌ Error: No se encontró el archivo de entrada '{INPUT_FILE}'.")
        return

    usuarios = []
    for linea in lineas:
        usuario = procesar_correo(linea)
        if usuario:
            usuarios.append(usuario)

    if not usuarios:
        print("⚠️ No se procesó ningún correo válido.")
        return

    # Escribir el CSV con encabezados exactos para LLDAP
    fieldnames = ["username", "email", "displayName", "password"]
    with open(OUTPUT_FILE, mode='w', newline='', encoding='utf-8') as outfile:
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(usuarios)

    print(f"✅ ¡Éxito! Se procesaron {len(usuarios)} usuarios y se guardaron en '{OUTPUT_FILE}'.\n")
    print("Ejemplo de registros generados:")
    for u in usuarios[:3]:
        print(f" - Username: {u['username']} | Name: {u['displayName']} | Pass: {u['password']}")

if __name__ == '__main__':
    main()