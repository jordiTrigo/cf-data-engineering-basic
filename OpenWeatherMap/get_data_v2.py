import requests
import pandas as pd
from geopy.geocoders import Nominatim
from geopy.extra.rate_limiter import RateLimiter
import datetime
import geopandas as gpd
import contextily as ctx
from skimage import io
import matplotlib.pyplot as plt
from matplotlib.offsetbox import AnnotationBbox, OffsetImage  
import time
import yaml
 


# Archivo de configuración
CONFIG_YAML_FILE = './config.yaml'

def get_yaml(path):
  '''
  Helper function to get yaml file contents.
  '''
  with open(path) as yaml_file:
      data = yaml.safe_load(yaml_file)

  return data


def obtener_coordenadas(geocode, city, country):
  response = geocode(query={"city": city, "country": country})
  return {
    "latitude": response.latitude,
    "longitude": response.longitude
  }

def get_df_geocodification(df):
  locator = Nominatim(user_agent=config['user_agent'])
  geocode = RateLimiter(locator.geocode, min_delay_seconds=1)

  df_coordenadas = df.apply(lambda x: obtener_coordenadas(geocode, x.city, x.country), axis=1)
  df = pd.concat([df, pd.json_normalize(df_coordenadas)], axis=1)

  return df


# Obtenemos los datos meteorologicos por ciudad
def obtener_datos_meteorologicos(row):
  my_url = f"{config['openweathermap']['base_url']}?lat={row.latitude}&lon={row.longitude}&appid={config['openweathermap']['api_key']}"
  my_response = requests.get(my_url)
  my_response_json = my_response.json()

  # my_response_json contiene una lista de diccionarios. 
  # Comprobamos si el valor de la llave "cod" es igual a "404", ya que eso significa que no 
  # hemos encontrado la ciudad.

  if my_response_json["cod"] != "404":
    my_response_json = my_response.json()
    
    sunset_utc = datetime.datetime.fromtimestamp(my_response_json["sys"]["sunset"])
    return {
        "temperatura": my_response_json["main"]["temp"] - 273.15,
        "presion": my_response_json["main"]["pressure"],
        "humedad": my_response_json["main"]["humidity"],
        "nubes": my_response_json["clouds"]["all"],
        "viento_speed": my_response_json["wind"]["speed"],
        "viento_deg": my_response_json["wind"]["deg"],
        "descripcion": my_response_json["weather"][0]["description"],
        "icono": my_response_json["weather"][0]["icon"],
        "sunset_utc": sunset_utc,
        "sunset_local": sunset_utc + datetime.timedelta(seconds=my_response_json["timezone"])
    }
  else:
    return {
      "error": "Ciudad no encontrada"
    }

def get_df_meteo_by_city(df):
    df_meteo = df.apply(lambda x: obtener_datos_meteorologicos(x), axis=1)
    df = pd.concat([df, pd.json_normalize(df_meteo)], axis=1)

    return df


def save_df_to_parquet(config, df):
    # filename = f'meteo_data_{time.strftime("%Y%m%d_%H%M%S")}'
    # filename_path = f'{config['meteodata']['path']}{filename}.parquet'

    filename_prefix = config['meteodata']['filename']
    filename_path = f"{config['meteodata']['path']}{filename_prefix.format(timestamp=time.strftime('%Y%m%d_%H%M%S'))}"

    df.to_parquet(filename_path, engine='fastparquet')


# Dibujamos el mapa
def get_geodataframe(df):
    geo_df = gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(df.longitude, df.latitude), crs=4326)
    return geo_df

def add_icon(ax, row):
  img = io.imread(f"{config['openweathermap']['url_icono']}{row.icono}@2x.png")
  img_offset = OffsetImage(img, zoom=.4, alpha=1, )
  ab = AnnotationBbox(img_offset, [row.geometry.x+150000, row.geometry.y-110000], frameon=False)
  ax.add_artist(ab)

def draw_map(geo_df):
    # Dibujamos la localización de la ciudad
    ax = geo_df.to_crs(epsg=3857).plot(figsize=(12,8), color="black")

    # Añadimos el icono
    #geo_df.to_crs(epsg=3857).apply(add_icon, axis=1)
    geo_df.to_crs(epsg=3857).apply(lambda row: add_icon(ax, row), axis=1)

    # Nombre de la ciudad
    geo_df.to_crs(epsg=3857).apply(lambda x: ax.annotate(text=f"{x.city}  ", fontsize=10, color="black", xy=x.geometry.centroid.coords[0], ha='right'), axis=1);

    # Temperatura registrada
    geo_df.to_crs(epsg=3857).apply(lambda x: ax.annotate(text=f" {round(x.temperatura)}°", fontsize=15, color="black", xy=x.geometry.centroid.coords[0], ha='left'), axis=1);

    # Márgenes del mapa
    xmin, ymin, xmax, ymax = geo_df.to_crs(epsg=3857).total_bounds
    margin_y = .2
    margin_x = .2
    y_margin = (ymax - ymin) * margin_y
    x_margin = (xmax - xmin) * margin_x

    ax.set_xlim(xmin - x_margin, xmax + x_margin)
    ax.set_ylim(ymin - y_margin, ymax + y_margin)

    # Añadimos el mapa base
    ctx.add_basemap(ax, source=ctx.providers.CartoDB.Positron)

    ax.set_axis_off()

    plt.show()



if __name__ == "__main__":
    # Obtenemos nuestro archivo de configuración

    try:
        config = get_yaml(CONFIG_YAML_FILE)
    except Exception as e:
        print(f'No existe el archivo de configuración {CONFIG_YAML_FILE}')
        exit(-1)

    # Cargamos el dataframe con las ciudades y países

    df = pd.DataFrame(config['cities'], columns=["city", "country"])

    # Necesitaremos realizar una geocodificación para cada ciudad, ya que el endpoint de la API de OpenWeatherMap 
    # necesita coordenadas geográficas de latitud y longitud. Para ello, utilizaremos el geocodificador Nominatim 
    # proporcionado por OpenStreetMap.

    df = get_df_geocodification(df)

    # Obtenemos los datos meteorologicos por ciudad

    df = get_df_meteo_by_city(df)

    # Guardamos el dataframe resultante en un archivo de tipo parquet

    save_df_to_parquet(config, df)

    # Utilizaremos las librerías Geopandas, contextily y Matplotlib para mostrar en un mapa los resultados.
    # Para ello convertiremos el DataFrame de pandas en un GeoDataFrame y crearemos una columna con coordenadas. 
    # Se establecerá el CRS en 4326, que define el sistema de coordenadas como WGS84 — World Geodetic System 1984, 
    # que utiliza latitud y longitud en grados (unidad).

    geo_df = get_geodataframe(df)

    # Dibujamos el mapa
    draw_map(geo_df)