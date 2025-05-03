from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from requests.auth import HTTPBasicAuth
import time
import shutil
import os

app = FastAPI()
INDISEARCH_IMAGE_URL = "https://indisearch.study/uploads"

UPLOAD_DIR = "/var/www/html/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
def make_zara_request(image_url = "https://static.zara.net/assets/public/d434/ddd0/4d3c449a9351/0976f98b78fe/02335003660-p/02335003660-p.jpg?ts=1740473267596&w=1500"):
    import requests
    from requests.auth import HTTPBasicAuth


    # Datos necesarios
    token_url = "https://auth.inditex.com:443/openam/oauth2/itxid/itxidmp/access_token"
    client_id = "CLIENT_ID_VALUE"
    client_secret = "CLIENT_SECRET_VALUE"

    data = {
        "grant_type": "client_credentials",
        "scope": "technology.catalog.read"
    }

    # Encabezados (User-Agent)
    headers = {
        "User-Agent": "OpenPlatform/1.0"
    }

    # Autenticación básica (como en -u "client_id:client_secret" de curl)
    auth = HTTPBasicAuth(client_id, client_secret)

    # Solicitud POST para obtener el access token
    response = requests.post(token_url, headers=headers, data=data, auth=auth)

    # Verificar la respuesta
    if response.status_code == 200:
        access_token_data = response.json()
        print("Access token obtenido correctamente:")
        print(access_token_data)
    else:
        print("Error al obtener el token:")
        print(f"Status Code: {response.status_code}")
        print(f"Response Body: {response.text}")
        return

    # URL de la API
    url = "https://api.inditex.com/pubvsearch/products"
    jwt_token = access_token_data['id_token']

    # Parámetros de consulta (query params)
    print(f"{image_url}")
    params = {
        "image": f"{image_url}"
    }

    # Encabezados (headers)
    headers = {
        "User-Agent": "OpenPlatform/1.0",
        "Authorization": f"Bearer {jwt_token}",
        "Content-Type": "application/json"
    }

    # Solicitud GET
    response = requests.get(url, headers=headers, params=params)

    # Verificar la respuesta
    if response.status_code == 200:
        products_data = response.json()
        print("Datos obtenidos correctamente:")
        print(products_data)
        return products_data
    else:
        print("Error al obtener los datos:")
        print(f"Status Code: {response.status_code}")
        print(f"Response Body: {response.text}")
        return {}


def get_images_from_product(url):

    # Configurar opciones para Chrome
    chrome_options = Options()
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--headless")  # Habilitar el modo headless

    # Modificar el user-agent para simular un navegador normal
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

    # Agregar otras configuraciones para evitar detección
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")  # Evitar que se detecte como automatizado
    chrome_options.add_argument("--remote-debugging-port=9222")  # Usar un puerto de depuración remoto
    chrome_options.add_argument("start-maximized")  # Maximizar la ventana
    chrome_options.add_argument("--disable-software-rasterizer")

    # Ruta a chromedriver (ajusta según tu sistema)
    service = Service("/usr/bin/chromedriver")  # Linux típico

    driver = webdriver.Chrome(service=service, options=chrome_options)

    driver.get(url)
    time.sleep(2) # Esperamos para que cargue la web



    content = driver.page_source
    driver.quit()



    soup = BeautifulSoup(content, "html.parser")

    # Encontrar todas las etiquetas <img>
    imagenes = soup.find_all("img")

    url_images = []
    # Extraer y mostrar las URLs de las imágenes
    for img in imagenes:
        src = img.get("src")
        if src and src.startswith("https://static.zara.net/assets/public"):
            url_images.append(src)

    return url_images


@app.post("/upload-image/")
async def upload_image(file: UploadFile = File(...)):
    file_path = os.path.join(UPLOAD_DIR, file.filename)


    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        buffer.flush()           # Fuerza a escribir los datos en el sistema operativo
        os.fsync(buffer.fileno()) # Fuerza a escribir los datos en disco físico


    print(f'Solicitando: {INDISEARCH_IMAGE_URL}/{file.filename}')
    zaraResponse = make_zara_request(f"{INDISEARCH_IMAGE_URL}/{file.filename}")

    data = []
    for product in zaraResponse:
        dataProduct = {}
        dataProduct['name'] = product['name']
        dataProduct['price'] = str(product['price']['value']['current'])
        dataProduct['shopURL'] = product['link']
        dataProduct['imageURL'] = get_images_from_product(product['link'])[0]
        dataProduct['brand'] = product['brand']
        dataProduct['isFavorite'] = False
        data.append(dataProduct)
    print('Enviado al cliente:')
    print(data)
    return JSONResponse(content=data)
