# Mi Oficina IA

Centro de control y fábrica de agentes de inteligencia artificial.

## Primera versión funcional

Aplicación estática (HTML, CSS y JavaScript) sin dependencias de compilación.

### Funciones
- Panel de resumen.
- Crear, editar, buscar y eliminar perfiles de agentes.
- Crear tareas asignadas a agentes.
- Guardar borradores y enviarlos a aprobación.
- Aprobar resultados o solicitar cambios.
- Exportar e importar respaldo JSON.
- Guardar preferencias del espacio.
- Manifiesto PWA y service worker para instalación/caché inicial.

## Probar
Abre `index.html` en un navegador. Para probar instalación PWA y service worker, publica con GitHub Pages o usa un servidor local HTTPS/localhost.

## Publicar con GitHub Pages
1. En GitHub abre **Settings → Pages**.
2. En **Build and deployment**, selecciona **Deploy from a branch**.
3. Elige la rama `main` y la carpeta `/(root)`.
4. Guarda y espera a que termine el despliegue.

## Límites actuales
Los datos se guardan en `localStorage` del navegador: no hay sincronización entre dispositivos ni backend. Los perfiles de agente son instrucciones configurables, no agentes autónomos conectados a un modelo. La investigación web, la generación real mediante IA, las integraciones de publicación, la autenticación y el almacenamiento compartido requieren una fase posterior. Aprobar un resultado no lo publica.

No pongas claves API ni secretos en el frontend. Para integrar modelos se debe crear un backend y guardar credenciales como variables de entorno.
