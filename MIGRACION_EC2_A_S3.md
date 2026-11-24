# Migración de EC2 a S3 + CloudFront

Plan recomendado para pasar el sitio estático de Astro de EC2/Docker/Certbot a S3, CloudFront y GitHub Actions con identidad OIDC. El objetivo es reducir la operación sin realizar el corte definitivo hasta comprobar que todo funciona.

## Convenciones del registro

- `[ ]` Pendiente
- `[-]` En progreso
- `[x]` Completado
- `[~]` Completado con revisión pendiente

## Estado general

| Fase | Estado | Evidencia / notas |
|---|---|---|
| 1. Inventario y preparación | [ ] |  |
| 2. Crear bucket S3 | [ ] |  |
| 3. Solicitar certificado ACM | [ ] |  |
| 4. Crear distribución CloudFront | [ ] |  |
| 5. Conectar Namecheap | [ ] |  |
| 6. Automatizar CI/CD | [ ] |  |
| 7. Migrar observabilidad | [ ] |  |
| 8. Limpiar Terraform y archivos obsoletos | [ ] |  |
| 9. Prueba final y retirada de EC2 | [ ] |  |

## Fase 1: Inventario y preparación

**Objetivo:** documentar exactamente qué contiene la infraestructura actual antes de cambiarla.

### Tareas

- [ ] Registrar EC2, Elastic IP, ECR, dominio, certificados y subdominios activos.
- [ ] Exportar una copia de los registros DNS actuales de Namecheap.
- [ ] Identificar las entradas actuales de `kuma.smol-ivan.xyz` y `analytics.smol-ivan.xyz`.
- [ ] Confirmar qué rutas genera Astro y cómo se sirven actualmente.
- [ ] Ejecutar el build local:

```bash
pnpm install --frozen-lockfile
pnpm run build
```

- [ ] Revisar el contenido generado en `dist/`.
- [ ] Guardar una copia del estado y de los archivos Terraform relevantes.

### Resultado esperado

- Carpeta `dist/` completa.
- Lista documentada de DNS, certificados y recursos AWS.
- Copia local o registrada del código actual antes de retirar servicios.

### Aprendizaje

- Qué archivos necesitan publicarse para que una página estática funcione.
- Qué rutas generan un `index.html` y cuáles generan un archivo directo.
- Qué recursos de la infraestructura son realmente necesarios.

### Evidencia / notas

<!-- Agregar aquí capturas, resultados de DNS, ARNs o decisiones tomadas. -->

## Fase 2: Crear el bucket S3

**Objetivo:** alojar los archivos generados sin exponer el bucket públicamente.

### Tareas

- [ ] Elegir un nombre único para el bucket.
- [ ] Crear el bucket en una región AWS definida.
- [ ] Activar el bloqueo de acceso público.
- [ ] Mantener un sitio privado o desactivar el website hosting público.
- [ ] Subir temporalmente una prueba:

```bash
aws s3 mb s3://NOMBRE-UNICO --region us-west-2
aws s3 sync dist/ s3://NOMBRE-UNICO --delete
```

- [ ] Comprobar que los objetos existen en S3.
- [ ] Comprobar que no es posible acceder al bucket directamente desde Internet.
- [ ] Crear posteriormente la bucket policy para CloudFront con OAC.

### Resultado esperado

- Los archivos están en S3.
- El bucket no está disponible públicamente.
- `aws s3 sync dist/ s3://NOMBRE-UNICO --delete` reemplaza el contenido publicado.

### Aprendizaje

- Diferencia entre un bucket privado y S3 Website Hosting público.
- Qué hace el parámetro `--delete` de `aws s3 sync`.
- Qué son Origin Access Control y bucket policies.

### Evidencia / notas

<!-- Registrar el nombre del bucket, región y cualquier prueba realizada. -->

## Fase 3: Solicitar el certificado ACM

**Objetivo:** obtener un certificado administrado y renovado automáticamente por AWS.

### Tareas

- [ ] Solicitar el certificado en **Norte de Virginia (`us-east-1`)**.
- [ ] Incluir `smol-ivan.xyz`.
- [ ] Incluir `www.smol-ivan.xyz`.
- [ ] Revisar opcionalmente si se necesita algún subdominio adicional.
- [ ] Copiar los CNAME de validación proporcionados por ACM.
- [ ] Crear las entradas CNAME correspondientes en Namecheap.
- [ ] Esperar hasta que ACM muestre el estado `Issued`.
- [ ] Registrar el ARN del certificado.

### Resultado esperado

- Certificado ACM con estado `Issued`.
- El certificado cubre el dominio raíz y `www`.

### Aprendizaje

- Por qué CloudFront requiere el certificado en `us-east-1`.
- Cómo funciona la validación DNS frente a la validación por correo.
- Qué significa que AWS gestione renovación y entrega del certificado.

### Evidencia / notas

<!-- Registrar el ARN, fecha de solicitud y nombres validados. -->

## Fase 4: Crear la distribución CloudFront

**Objetivo:** habilitar CDN, HTTPS y entrega protegida desde S3.

### Tareas

- [ ] Crear una distribución apuntando al bucket mediante Origin Access Control.
- [ ] Configurar `smol-ivan.xyz` como alternate domain name.
- [ ] Configurar `www.smol-ivan.xyz` si se desea servir directamente.
- [ ] Seleccionar el certificado ACM solicitado.
- [ ] Redirigir HTTP a HTTPS.
- [ ] Activar compresión si corresponde.
- [ ] Configurar `/404.html` como custom error response.
- [ ] Aplicar la bucket policy que propone AWS para CloudFront.
- [ ] Mantener el comportamiento de caché bajo revisión hasta completar las pruebas.
- [ ] Opcionalmente diferenciar caché para:
  - HTML.
  - Archivos `_astro/*` versionados.

### Resultado esperado

- El sitio funciona desde `https://xxxxxxxx.cloudfront.net`.
- El acceso directo al bucket está bloqueado.
- HTTP redirige a HTTPS.
- Una ruta inexistente muestra la página 404 de Astro.

### Pruebas

```bash
curl -I https://xxxxxxxx.cloudfront.net/
curl -I https://xxxxxxxx.cloudfront.net/posts/
curl -I https://xxxxxxxx.cloudfront.net/404.html
```

Comprobar también:

- [ ] Página principal.
- [ ] Página de posts.
- [ ] Página de proyectos.
- [ ] Página de sobre mí.
- [ ] Markdown y diagramas.
- [ ] Assets JavaScript y CSS.
- [ ] Tema claro/oscuro.
- [ ] View Transitions.

### Aprendizaje

- Qué son edge locations.
- Qué significa origin, distribution y cache behavior.
- Cuándo se necesita una invalidación.
- Qué diferencia existe entre cachear HTML y assets versionados.

### Evidencia / notas

<!-- Registrar el dominio temporal, distribution ID y pruebas. -->

## Fase 5: Conectar Namecheap

**Objetivo:** trasladar el dominio sin retirar inmediatamente EC2.

### Tareas

- [ ] Revisar todos los registros DNS existentes antes de modificar nada.
- [ ] Reducir el TTL de los registros que van a cambiar.
- [ ] Crear el registro del dominio raíz hacia CloudFront.
- [ ] Decidir entre servir `www` desde CloudFront o redirigirlo al dominio raíz.
- [ ] Configurar `www` con el método disponible en Namecheap.
- [ ] Confirmar que los registros MX, TXT y otros registros necesarios no cambian accidentalmente.
- [ ] Mantener EC2 activo mientras se verifica el nuevo dominio.
- [ ] Mantener temporalmente los registros de Kuma y Umami si todavía son necesarios.

### Pruebas

```bash
dig smol-ivan.xyz
dig www.smol-ivan.xyz
curl -I https://smol-ivan.xyz
curl -I https://www.smol-ivan.xyz
```

Comprobar:

- [ ] DNS resuelve a CloudFront.
- [ ] HTTPS usa el certificado ACM.
- [ ] La ruta raíz funciona.
- [ ] `www` funciona según la decisión tomada.
- [ ] HTTP redirige a HTTPS.

### Resultado esperado

- El dominio apunta a CloudFront.
- El sitio continúa disponible durante el periodo de migración.
- EC2 permanece como respaldo temporal.

### Aprendizaje

- Diferencia entre CNAME y ALIAS/ANAME.
- Por qué un dominio raíz no puede apuntar directamente a muchos endpoints sin soporte especial del proveedor.
- Cómo los TTL y la propagación DNS afectan una migración.
- Por qué no conviene apuntar un dominio directamente al endpoint público de S3.

### Evidencia / notas

<!-- Registrar registros anteriores y nuevos, TTL y hora del cambio. -->

## Fase 6: Automatizar CI/CD

**Objetivo:** reemplazar Docker y SSH por una publicación auditable usando GitHub Actions.

### Tareas

- [ ] Crear un rol IAM para GitHub Actions.
- [ ] Configurar confianza OIDC con GitHub.
- [ ] Limitar permisos al bucket S3 requerido.
- [ ] Limitar permisos a la invalidación de CloudFront requerida.
- [ ] Eliminar credenciales AWS permanentes de GitHub si ya existieran.
- [ ] Mantener las tareas de validación existentes:
  - [ ] Prettier.
  - [ ] `pnpm run check`.
- [ ] Agregar `pnpm run build` al workflow de despliegue.
- [ ] Sincronizar `dist/` con S3:

```bash
aws s3 sync dist/ s3://NOMBRE-UNICO --delete
```

- [ ] Invalidar CloudFront:

```bash
aws cloudfront create-invalidation \
    --distribution-id DISTRIBUTION-ID \
    --paths "/*"
```

- [ ] Eliminar el paso de construir Docker.
- [ ] Eliminar el paso de publicar a ECR.
- [ ] Eliminar el paso de SCP.
- [ ] Eliminar el paso de SSH.
- [ ] Eliminar o actualizar la validación Docker si ya no existe Docker en el proyecto.
- [ ] Realizar una publicación de prueba con un cambio pequeño.

### Resultado esperado

- Un push a `main` ejecuta:
  1. Validación.
  2. Build.
  3. Sincronización con S3.
  4. Invalidación de CloudFront.
- GitHub Actions no requiere llaves AWS permanentes.

### Aprendizaje

- Cómo funciona una federación OIDC de GitHub con AWS.
- Qué significa aplicar menor privilegio en IAM.
- Por qué una invalidación no sustituye una política de caché adecuada.
- Qué políticas y permisos son necesarios para este flujo, y cuáles no.

### Evidencia / notas

<!-- Registrar rol IAM, logs del workflow y ejecución exitosa. -->

## Fase 7: Migrar observabilidad

**Objetivo:** decidir qué reemplaza a Uptime Kuma y Umami antes de retirar EC2.

### Decisiones

- [ ] Elegir una solución para uptime/missing disponibilidad.
- [ ] Elegir una solución para analítica.
- [ ] Documentar si se conserva o pierde historial existente.
- [ ] Decidir si los subdominios deben mantenerse, eliminarse o redirigirse.

### Opción para Uptime Kuma

- [ ] Crear una cuenta o instancia de Uptime Kuma fuera de EC2, si se necesita conservarlo.
- [ ] Configurar AWS CloudWatch Synthetics.
- [ ] Configurar Healthchecks.io, UptimeRobot u otro proveedor.
- [ ] Crear una comprobación externa del dominio principal.
- [ ] Configurar alertas por correo o canal elegido.

### Opción para Umami

- [ ] Evaluar Umami Cloud.
- [ ] Evaluar alojar Umami fuera de EC2.
- [ ] Evaluar eliminar la analítica si no aporta suficiente valor.
- [ ] Obtener el nuevo script o endpoint.
- [ ] Reemplazar o eliminar esta sección en `src/layouts/Layout.astro`:

```astro
src="https://analytics.smol-ivan.xyz/script.js"
```

### Eliminación posterior

- [ ] Eliminar los bloques Nginx de Kuma y Umami.
- [ ] Quitar las referencias a `kuma.smol-ivan.xyz`.
- [ ] Quitar las referencias a `analytics.smol-ivan.xyz`.
- [ ] Eliminar los registros DNS obsoletos una vez comprobado que no se usan.

### Resultado esperado

- El sitio tiene una comprobación externa básica de disponibilidad.
- No quedan scripts o DNS apuntando a servicios que se retirarán.
- Se conserva o migra deliberadamente el historial necesario.

### Aprendizaje

- Diferencia entre métricas internas, pruebas externas y analítica web.
- Qué datos recopila cada opción y qué implicaciones de privacidad tiene.
- Qué coste operativo añade conservar servicios propios.

### Evidencia / notas

<!-- Registrar proveedor elegido, configuración de alertas y URL de comprobación. -->

## Fase 8: Limpiar Terraform y archivos obsoletos

**Objetivo:** hacer que el repositorio represente únicamente la arquitectura vigente.

### Tareas

- [ ] Diseñar Terraform para S3, CloudFront y OAC.
- [ ] Diseñar Terraform para el rol y proveedor OIDC de GitHub.
- [ ] Diseñar la política IAM mínima de despliegue.
- [ ] Decidir si ACM se administra mediante Terraform o manualmente.
- [ ] Crear los recursos nuevos antes de eliminar los antiguos.
- [ ] Revisar que los nuevos recursos tienen nombres y tags claros.
- [ ] Ejecutar:

```bash
terraform fmt
terraform validate
terraform plan
```

- [ ] Documentar antes de aplicar qué recursos se destruirán.
- [ ] Aplicar Terraform solo después de revisar el plan.
- [ ] Eliminar o retirar los módulos obsoletos:
  - [ ] `compute`.
  - [ ] `ecr`.
  - [ ] Certbot.
  - [ ] Reglas de red específicas de EC2 si ya no son necesarias.
- [ ] Eliminar archivos obsoletos únicamente después del corte:
  - [ ] `Dockerfile`.
  - [ ] `docker-compose.yml`.
  - [ ] `nginx/nginx.conf`.
  - [ ] Workflow de despliegue EC2.
  - [ ] Workflow de Docker.
  - [ ] Workflow de monitoreo si se retira completamente.

### Resultado esperado

- Terraform representa S3, CloudFront y OIDC.
- El repositorio no contiene flujos Docker/SSH activos.
- Las operaciones creadoras y destructoras están documentadas.

### Aprendizaje

- Cómo leer un plan Terraform antes de aplicarlo.
- Cómo migrar recursos sin destruir accidentalmente infraestructura compartida.
- Qué significa administrar DNS y certificados como infraestructura.

### Evidencia / notas

<!-- Registrar resumen de terraform plan, decisiones y fecha de apply. -->

## Fase 9: Prueba final y retirada de EC2

**Objetivo:** confirmar que todo funciona antes de eliminar infraestructura.

### Lista de comprobación funcional

- [ ] Página principal.
- [ ] Página de proyectos.
- [ ] Página de posts.
- [ ] Página de sobre mí.
- [ ] Rutas individuales de posts.
- [ ] Navegación con View Transitions.
- [ ] Tema claro/oscuro.
- [ ] Imágenes y assets.
- [ ] Archivos CSS y JavaScript.
- [ ] Sitemap o robots, si existen.
- [ ] Página 404.
- [ ] Certificado válido.
- [ ] HTTP redirige a HTTPS.
- [ ] `www` se comporta según lo definido.
- [ ] Publicación genera el contenido nuevo.
- [ ] Archivos retirados desaparecen tras `s3 sync --delete`.
- [ ] Caché entrega assets actualizados.
- [ ] GitHub Actions publica sin Docker ni SSH.
- [ ] Kum/Umami han sido migrados o eliminados.

### Periodo de seguridad

- [ ] Mantener EC2 activo 7–14 días.
- [ ] Detener temporalmente el servicio antiguo sin destruirlo.
- [ ] Observar DNS, CloudFront y monitoreo durante varios días.
- [ ] Revisar errores 404 o recursos perdidos.
- [ ] Conservar una instantánea o documento del estado anterior.
- [ ] Bajar o terminar EC2.
- [ ] Terminar la Elastic IP si ya no se usa.
- [ ] Eliminar ECR si ya no contiene imágenes necesarias.
- [ ] Eliminar volúmenes Docker o datos de monitoreo solo después de decidir si se conservan.
- [ ] Eliminar los registros DNS de servicios retirados.

### Resultado esperado

- Migración reversible durante el periodo de transición.
- El sitio depende únicamente de S3, CloudFront y el pipeline.
- Se eliminan dependencias innecesarias de EC2, Docker y Certbot.

### Evidencia / notas

<!-- Registrar fecha del corte, recursos eliminados y comprobaciones finales. -->

## Arquitectura objetivo

```text
Cambio en GitHub
      |
      v
GitHub Actions
      |
      | OIDC + menor privilegio
      v
S3 <- build de Astro -> CloudFront -> HTTPS <- Namecheap DNS
                           |
                           v
                       Visitantes
```

## Registro breve de decisiones

| Fecha | Decisión | Razón | Revisar |
|---|---|---|---|
|  | Nombre del bucket |  |  |
|  | Región de S3 |  |  |
|  | Comportamiento del dominio `www` |  |  |
|  | Solución de uptime |  |  |
|  | Solución de analítica |  |  |
|  | Fecha del corte EC2 |  |  |
