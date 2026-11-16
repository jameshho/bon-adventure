"""Explicit Spanish noun genders for the legacy vocabulary (no suffix guessing)."""
from pathlib import Path
import json
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
import word_data  # data/words.json is the only word source
data=word_data.load()
v=word_data.vocabulary(data)
feminine=set('''acera aguja alfombra alfombrilla ambulancia anatomía arena baldosa bandeja bandera barandilla barra base bañera biblioteca biología boca bolsa botella báscula bóveda cabecera cabeza cafetera caja calle cama camilla campana carpeta carretera cesta cinta cisterna clínica columna comida comisaría consola cortina cruz cumbrera célula cómoda despensa electrónica encimera entrada escuela esponja espátula estufa etiqueta farmacia farola fila flor fotografía fuente geografía guitarra habitación hoja iglesia imagenología insignia jardinera jarra jeringa lechuga lente lista llama luz lámina lámpara maceta magdalena manga mano manta mesa mochila moldura montaña motocicleta máquina nariz nota olla oreja pantalla pantufla papelera parada pared partitura pasta pelota pelvis percha perilla persona pierna pimienta pizarra placa planta plaza policía puerta radio radiografía ranura receta rejilla revista roca rueda sal sartén sección servilleta silla sopa sábana tabla tapa taza tecnología tela tienda tierra toalla toallita tostadora valla vela venda ventana ventanilla vidriera viga zona'''.split())
plural_m={'archivos','electrodomésticos','videojuegos'}
plural_f={'frutas','llaves','muletas'}
for k,value in v.items():
    if value.startswith(('el ','la ','los ','las ')):continue
    first=value.split()[0]
    article='las' if first in plural_f else 'los' if first in plural_m else 'la' if first in feminine else 'el'
    v[k]=article+' '+value
v.update({'teacher':'el profesor / la profesora','police officer':'el policía / la policía','doctor':'el médico / la médica','nurse':'el enfermero / la enfermera','firefighter':'el bombero / la bombera','student':'el estudiante / la estudiante','child':'el niño / la niña','cook':'el cocinero / la cocinera','cashier':'el cajero / la cajera','driver':'el conductor / la conductora','motorcycle':'la motocicleta / la moto','car':'el coche / el carro','terminal':'el terminal'})
# Preserve alternative regional forms already established in the project.
v.pop('terminal',None)
for k,value in v.items(): data['words'][k]['spanish']=value
word_data.save(data)
