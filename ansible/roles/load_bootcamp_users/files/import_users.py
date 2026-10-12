import csv
import sys
import subprocess
import requests


def get_auth_token(base_url, admin_user, admin_password):
    """
    LLDAP NO tiene una mutación GraphQL "login".
    La autenticación se hace contra el endpoint REST /auth/simple/login,
    que devuelve un JWT. Ese JWT es el que luego se usa como Bearer token
    para las mutaciones/consultas en /api/graphql.

    Referencia oficial:
    https://github.com/lldap/lldap/blob/main/docs/scripting.md
    """
    auth_url = f"{base_url}/auth/simple/login"
    payload = {"username": admin_user, "password": admin_password}

    res = requests.post(auth_url, json=payload)

    if res.status_code == 200:
        data = res.json()
        if "token" in data:
            print(f"🔑 Autenticado exitosamente como '{admin_user}'")
            return data["token"]

    print(f"❌ Error de autenticación. Status HTTP: {res.status_code}")
    print(f"Respuesta del servidor:\n{res.text}")
    raise Exception("No se pudo iniciar sesión con las credenciales proporcionadas.")


def create_user(graphql_url, token, username, email, display_name):
    """
    IMPORTANTE: CreateUserInput de LLDAP NO tiene campo "password".
    LLDAP no acepta contraseñas en texto plano por GraphQL; la contraseña
    se asigna aparte mediante el protocolo OPAQUE (ver set_user_password).
    """
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    mutation = """
    mutation CreateUser($user: CreateUserInput!) {
        createUser(user: $user) {
            id
        }
    }
    """
    variables = {
        "user": {
            "id": username,
            "email": email,
            "displayName": display_name
        }
    }

    res = requests.post(graphql_url, json={'query': mutation, 'variables': variables}, headers=headers)
    body = res.json()

    if res.status_code == 200 and "errors" not in body:
        print(f"✅ Usuario creado correctamente: {username}")
        return True

    # Si ya existe (por id o por email duplicado), lo tratamos como no-fatal:
    # igual intentamos fijar su password. LLDAP puede devolver distintos
    # mensajes según la causa exacta del duplicado.
    error_text = str(body.get("errors", res.text)).lower()
    ya_existe = (
        "already exists" in error_text
        or "unique constraint" in error_text
        or "lowercase_email" in error_text
    )
    if ya_existe:
        print(f"ℹ️ El usuario {username} ya existía, se continúa con su contraseña.")
        return True

    print(f"⚠️ Atención con usuario {username}: {body.get('errors', res.text)}")
    return False


def set_user_password(container_name, internal_base_url, admin_user, admin_password, username, password):
    """
    LLDAP usa el protocolo OPAQUE para las contraseñas: no se puede mandar
    la contraseña por un POST/mutación normal. El propio proyecto LLDAP
    resuelve esto con el binario 'lldap_set_password', incluido dentro de
    su imagen oficial de Docker en /app/lldap_set_password.

    Por eso lo invocamos con `docker exec` sobre el contenedor de LLDAP,
    usando el puerto INTERNO del contenedor (no el publicado en el host).

    Referencia: https://github.com/lldap/lldap/discussions/749
    """
    cmd = [
        "docker", "exec", container_name,
        "/app/lldap_set_password",
        "--username", username,
        "--password", password,
        "--admin-username", admin_user,
        "--admin-password", admin_password,
        "--base-url", internal_base_url,
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode == 0:
        print(f"🔐 Contraseña asignada correctamente a: {username}")
    else:
        detalle = (result.stderr or result.stdout).strip()
        print(f"⚠️ No se pudo asignar contraseña a {username}: {detalle}")


def main():
    if len(sys.argv) < 5:
        print("Uso: python3 import_users.py <LLDAP_BASE_URL> <ADMIN_USER> <ADMIN_PASS> <CSV_PATH> "
              "[LLDAP_CONTAINER_NAME] [LLDAP_INTERNAL_URL]")
        print('Ejemplo: python3 import_users.py "http://127.0.0.1:1717" admin adminpassword123 '
              'usuarios.csv lldap http://localhost:17170')
        sys.exit(1)

    # URL BASE de LLDAP tal como se ve desde fuera del contenedor (para login y GraphQL)
    base_url = sys.argv[1].rstrip("/")
    admin_user = sys.argv[2]
    admin_password = sys.argv[3]
    csv_path = sys.argv[4]

    # Nombre del contenedor y URL interna (puerto interno del contenedor: 17170),
    # usados solo para invocar lldap_set_password vía docker exec.
    container_name = sys.argv[5] if len(sys.argv) > 5 else "lldap"
    internal_base_url = sys.argv[6] if len(sys.argv) > 6 else "http://localhost:17170"

    graphql_url = f"{base_url}/api/graphql"

    token = get_auth_token(base_url, admin_user, admin_password)

    with open(csv_path, mode='r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            username = row['username']
            created_ok = create_user(graphql_url, token, username, row['email'], row['displayName'])
            if created_ok:
                set_user_password(
                    container_name, internal_base_url,
                    admin_user, admin_password,
                    username, row['password']
                )


if __name__ == '__main__':
    main()