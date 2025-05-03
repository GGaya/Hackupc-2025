
# 👗 IndiSearch

**IndiSearch** es una aplicación móvil pensada para los amantes de la moda que quieren encontrar fácilmente prendas similares a las que ven en su día a día. ¿Te ha gustado una pieza que viste por la calle o en redes sociales? Solo tienes que hacerle una foto (o elegir una desde tu galería) y nosotros te ayudamos a encontrar opciones parecidas en la tienda **Zara**.

## 🚀 ¿Qué puedes hacer con IndiSearch?

- 📸 Tomar una foto de una prenda o cargarla desde tu galería.
- 🛍️ Obtener resultados de prendas similares disponibles en Zara.
- ❤️ Guardar tus favoritos para no perder de vista lo que más te gustó.

## 🧠 ¿Cómo funciona?

La aplicación cuenta con un backend que se encarga de forma transparente de:

- Almacenar las imágenes que subes.
- Procesar y comparar visualmente esas imágenes con un catálogo de productos de Zara.
- Devolverte los resultados más parecidos sin que tengas que hacer nada más.

## ⚙️ Tecnologías utilizadas

- Frontend: Flutter, Dart
- Backend: FastAPI (Python)
- Web scraping/API: Selenium, requests, BeautyShop
- Almacenamiento seguro: HTTPS con Apache2
- Integración externa: Credenciales de [developer.inditex.com/](https://developer.inditex.com/)

## 📦 Instalación y uso

### 1. Aplicación móvil (Flutter)

#### Requisitos:
- [Flutter](https://flutter.dev/docs/get-started/install)
- Dart SDK
- Un dispositivo o emulador Android/iOS

#### Pasos:
```bash
# Clona el repositorio
git clone https://github.com/tuusuario/IndiSearch.git
cd IndiSearch/app

# Asegúrate de tener todas las dependencias
flutter pub get

# Cambia las URLs del endpoint del servidor en el código (por ejemplo, en services/api.dart)

# Ejecuta la aplicación
flutter run

```
## 🖥️ Instalación del Servidor (Backend API)

### Requisitos

- Apache2 con configuración HTTPS y certificados SSL válidos (Let’s Encrypt, etc.)
- Python 3.x
- Paquetes de Python:
    - `selenium`
    - `requests`
    - `fastapi`
    - `beautyshop`
- Credenciales válidas de acceso a la API de Zara ([developer.inditex.com](https://developer.inditex.com))

### Pasos de instalación

1. **Clonar el repositorio y acceder a la carpeta del backend**

   ```bash
   git clone https://github.com/GGaya/IndiSearch.git

#### 2. Instala las dependencias de Python
```bash
pip install selenium requests fastapi beautyshop
```

#### 3. Configura el archivo `api.py`

Antes de ejecutar el servidor, debes editar el archivo `api.py` para asegurarte de que todos los valores estén correctamente configurados:

- **URLs del backend:** modifica las rutas si tu servidor no está en localhost o si has cambiado el dominio.
- **Credenciales de Zara:**
    - Usuario (email registrado en [developer.inditex.com](https://developer.inditex.com))
    - Contraseña o token de acceso
- **Certificados SSL:**
    - Ruta al archivo `privkey.pem`
    - Ruta al archivo `fullchain.pem`

Asegúrate de que las credenciales estén almacenadas de forma segura y nunca las publiques en el repositorio.

#### 4. Ejecuta el servidor con Uvicorn y HTTPS

Una vez configurado el archivo `api.py` y con los certificados SSL, puedes lanzar el servidor con el siguiente comando:

```bash
uvicorn api:app \
  --host 0.0.0.0 \
  --port 8443 \
  --ssl-keyfile /etc/letsencrypt/live/TU_DOMINIO/privkey.pem \
  --ssl-certfile /etc/letsencrypt/live/TU_DOMINIO/fullchain.pem
```
Esto levantará la API en el puerto `8443` con conexión segura (HTTPS).

> ⚠️ **Asegúrate de:**
> - Tener abiertos los puertos `8443` y `443` en el firewall del servidor.
> - Que tu dominio apunte correctamente a la IP pública del servidor.
