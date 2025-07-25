library(stringr)
library(fs)
library(rio)
library(tidyverse)
library(googlesheets4)
library(googledrive)
library(magick)

#### IMPORTO DATOS DESDE MI CARPETA #######

datos = import("./FORMULARIO/FORMULARIO PRUEBA - LIBRO POSTERS.csv")|>
  select(-1) |>
  rownames_to_column("ID")|>
  mutate(ID = as.integer(ID))
names(datos)= c("ID",
                      "Tipo",
                      "Titulo",
                      "Autores",
                      "Mail",
                      "Resumen",
                      "Poster_url")

##### DESCARGO IMAGENES A MI UNIDAD ######
drive_auth()
gs4_auth()
# Obtener IDs de archivos (ejemplo: columna "Imagen" con URLs)
urls_imagenes <- datos$Poster_url

ruta = "C:/Users/usuario/Documents/JUAN/BYDE/2025/COMISIÓN JORNADAS INTEGRADAS 2025/POSTERS_JIA_FCAUNJU_2025/ARTICULOS/IMAGENES/"
for (url in urls_imagenes) {
  file_id = drive_get(as_id(url))$id
  drive_download(as_id(file_id), 
                 path = paste0(ruta, file_id, ".png"))
}

#################################

#### importación de imagenes #####

ruta = "C:/Users/usuario/Documents/JUAN/BYDE/2025/COMISIÓN JORNADAS INTEGRADAS 2025/POSTERS_JIA_FCAUNJU_2025/ARTICULOS/IMAGENES"
imagenes = list.files(
  ruta
)
rutared = "./IMAGENES"
imagenes = file.path(
  rutared,imagenes
)

# 2. Función para crear archivos QMD

for (i in 1:nrow(datos)){
  contenido = datos[i,]
  imagen = contenido[["Poster_url"]]|>
    str_extract("(?<=id=)[^&]*")
  contenido_qmd = c(
    paste0("# ", contenido$Titulo),
    "\n",
    "## Autores: ", contenido$Autores,
    "\n",
    "## Resumen: ", contenido$Resumen,
    "\n",
    "\n",
    paste0(
      "![Póster del trabajo](",
      imagenes[grepl(imagen,imagenes)],")"
    )
  )
  nombre_archivo = str_to_lower(contenido$Titulo) |>
    str_remove_all("[^a-z0-9 ]") |>
    str_replace_all(" ", "_") |>
    str_c(".qmd")
  ruta2 = "C:/Users/usuario/Documents/JUAN/BYDE/2025/COMISIÓN JORNADAS INTEGRADAS 2025/POSTERS_JIA_FCAUNJU_2025/ARTICULOS"
  writeLines(contenido_qmd, 
             file.path(
               ruta2, 
               nombre_archivo|>
                 substr(start = 1,stop = 25)|>
                 paste0(".qmd")))
  
}


# 4. Actualizar _quarto.yml
ruta3 = "./ARTICULOS"
archivos = list.files(ruta3,pattern = "qmd")
actualizar_configuracion <- function() {
  # Leer configuración actual
  config <- yaml::read_yaml("_quarto.yml")
  
  # Obtener lista actual de páginas
  paginas_actuales <- config$book$chapters
  
  # Añadir nuevos archivos (sin duplicados)
  nuevos_archivos <- setdiff(
    file.path(ruta3,archivos),
    paginas_actuales
  )
  
  if (length(nuevos_archivos) > 0) {
    config$book$chapters <- c(paginas_actuales, nuevos_archivos)
    yaml::write_yaml(config, "_quarto.yml")
  }
}

actualizar_configuracion()


