# Chargebee PoC — company external recurring payments

Esta PoC valida que company puede usar Chargebee como billing engine, recibir eventos por webhook, ejecutar el pago por fuera de Chargebee y luego marcar la invoice como pagada con `record_payment`.

## Resultado que se quiere validar

```txt
Chargebee crea subscription
→ Chargebee genera invoice payment_due
→ Chargebee envía webhook al backend de company
→ company ejecutaría el pago crypto/onchain
→ company llama record_payment
→ Chargebee marca invoice paid
→ Chargebee envía invoice_updated / payment_succeeded
```

## 0. Requisitos

Necesitás:

- Cuenta sandbox/test de Chargebee.
- Full-Access API Key de Chargebee.
- Node.js instalado.
- curl instalado.
- WSL/Linux terminal.
- cloudflared para exponer el webhook local.

No hace falta `npm install` para estos scripts.

## 1. Configuración inicial de Chargebee

Al crear la cuenta/test site usamos:

```txt
What are you looking to monetize? Software/Apps
Number of employees: 1-9
Host my data in: US Data Center
```

Para conseguir la API key:

```txt
Settings
→ Configure Chargebee
→ API Keys and Webhooks
→ API Keys
→ usar Full-Access Key
```

No usar la publishable key. Para estos scripts se usa la Full-Access Key.

## 2. Configurar `.env`

Desde la carpeta del proyecto:

```bash
cd ~/undr/yummy/PoC/chargebee
```

Crear o editar `.env`:

```bash
nano .env
```

Contenido base:

```txt
CHARGEBEE_SITE="comunyt-test"
CHARGEBEE_API_KEY="TU_FULL_ACCESS_KEY"

MERCHANT_ID="merchant-demo-001"

ITEM_FAMILY_ID="comunyt-family"
ITEM_FAMILY_NAME="Comunyt Demo Family"

ITEM_ID="comunyt-demo-plan"
ITEM_NAME="comunyt Demo Subscription"

ITEM_PRICE_ID="comunyt-demo-plan-usd-monthly"
ITEM_PRICE_NAME="comunyt Demo Plan USD Monthly"
ITEM_PRICE_AMOUNT="1000"
ITEM_PRICE_CURRENCY="USD"

CUSTOMER_ID="comunyt-user-demo-001"
CUSTOMER_EMAIL="demo-user@comunyt.test"
CUSTOMER_FIRST_NAME="Demo"
CUSTOMER_LAST_NAME="User"

INVOICE_ID=""
SUBSCRIPTION_ID=""
```

Notas:

- `CHARGEBEE_SITE` es el subdominio de Chargebee. Si tu URL es `https://comunyt-test.chargebee.com`, entonces el site es `comunyt-test`.
- `ITEM_PRICE_AMOUNT="1000"` significa 10.00 USD porque Chargebee usa cents.
- `auto_collection=off` se usa para que Chargebee no intente cobrar con tarjeta/gateway. company registra pagos externos.

## 3. Dar permisos de ejecución

```bash
chmod +x scripts/*.sh
```

## 4. Validar autenticación

```bash
./scripts/00_check_auth.sh
```

Verificar:

```bash
cat data/00_auth_check.pretty.json
```

Resultado esperado:

```txt
No debe aparecer api_error_code.
Debe devolver una respuesta válida de Chargebee.
```

## 5. Crear Item Family

Chargebee Product Catalog 2.0 requiere crear primero una Item Family.

```bash
./scripts/00b_create_item_family.sh
```

Verificar:

```bash
cat data/00b_create_item_family.pretty.json
```

Resultado esperado:

```txt
item_family.id = comunyt-family
item_family.status = active
```

## 6. Crear Item / Plan

```bash
./scripts/01_create_item.sh
```

Verificar:

```bash
cat data/01_create_item.pretty.json
```

Resultado esperado:

```txt
item.id = comunyt-demo-plan
item.type = plan
item.item_family_id = comunyt-family
item.status = active
```

## 7. Crear Item Price mensual

```bash
./scripts/02_create_item_price.sh
```

Verificar:

```bash
cat data/02_create_item_price.pretty.json
```

Resultado esperado:

```txt
item_price.id = comunyt-demo-plan-usd-monthly
price = 1000
period = 1
period_unit = month
currency_code = USD
status = active
```

Esto valida que company puede crear catálogo y pricing recurrente vía API.

## 8. Crear Customer sin tarjeta

```bash
./scripts/03_create_customer.sh
```

Verificar:

```bash
cat data/03_create_customer.pretty.json
```

Resultado esperado:

```txt
customer.id = comunyt-user-demo-001
auto_collection = off
card_status = no_card
```

Esto es clave: el customer existe sin payment method tradicional.

## 9. Crear Subscription con Product Catalog 2.0

```bash
./scripts/04_create_subscription.sh
```

Verificar:

```bash
cat data/04_create_subscription.pretty.json
```

Resultado esperado:

```txt
subscription.status = active
subscription.auto_collection = off
invoice.status = payment_due
invoice.recurring = true
invoice.amount_due = 1000
```

Copiar estos valores desde el JSON:

```txt
subscription.id
invoice.id
```

Editar `.env`:

```bash
nano .env
```

Agregar por ejemplo:

```txt
SUBSCRIPTION_ID="169m1FVKMxCde1EyX"
INVOICE_ID="1"
```

Usar los IDs reales que devuelva tu ejecución.

## 10. Ver invoice pendiente

```bash
./scripts/06_retrieve_invoice.sh && cat data/06_retrieve_invoice.pretty.json
```

Resultado esperado antes del pago:

```txt
invoice.status = payment_due
amount_due = 1000
amount_paid = 0
```

## 11. Registrar pago externo/offline

Este paso simula lo que haría company después de cobrar crypto/onchain.

```bash
./scripts/07_record_payment.sh
```

Verificar:

```bash
cat data/07_record_payment.pretty.json
```

Resultado esperado:

```txt
invoice.status = paid
amount_due = 0
amount_paid = 1000
transaction.status = success
transaction.gateway = not_applicable
transaction.payment_method = bank_transfer
```

Esto valida que Chargebee acepta pagos externos y marca la invoice como pagada.

## 12. Verificar invoice pagada

```bash
./scripts/06_retrieve_invoice.sh && cat data/06_retrieve_invoice.pretty.json
```

Resultado esperado:

```txt
status = paid
amount_due = 0
linked_payments existe
```

## 13. Verificar subscription activa después del pago

```bash
./scripts/08_retrieve_subscription.sh && cat data/08_retrieve_subscription.pretty.json
```

Resultado esperado:

```txt
subscription.status = active
auto_collection = off
due_invoices_count = 0
next_billing_at existe
mrr = 1000
```

Esto valida que pagar externamente no rompe el ciclo de billing.

## 14. Verificar que no queden invoices pendientes

```bash
./scripts/05_list_due_invoices.sh && cat data/05_list_due_invoices.pretty.json
```

Resultado esperado:

```txt
list = []
```

Esto confirma que la invoice ya no está como `payment_due`.

## 15. Instalar cloudflared para probar webhooks reales

Si no tenés ngrok, usar cloudflared.

Instalar:

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared && chmod +x cloudflared && sudo mv cloudflared /usr/local/bin/cloudflared
```

## 16. Levantar webhook receiver local

Abrir una terminal nueva. Terminal 1:

```bash
cd ~/undr/yummy/PoC/chargebee && node scripts/09_mock_webhook_receiver.mjs
```

Resultado esperado:

```txt
Mock webhook receiver listening on http://localhost:8787/chargebee/webhook
```

No cerrar esta terminal.

## 17. Exponer webhook con cloudflared

Abrir otra terminal nueva. Terminal 2:

```bash
cloudflared tunnel --url http://localhost:8787
```

Copiar la URL pública que devuelve, por ejemplo:

```txt
https://relying-achieving-transaction-pamela.trycloudflare.com
```

No cerrar esta terminal.

## 18. Configurar webhook en Chargebee

En Chargebee:

```txt
Settings
→ Configure Chargebee
→ API Keys and Webhooks
→ Webhooks
→ Add Webhook
```

Completar:

```txt
Webhook Name: company Local Webhook
Webhook URL: https://TU_URL_TRYCLOUDFLARE.trycloudflare.com/chargebee/webhook
Protect webhook URL with basic authentication: OFF
API version: Version 2
Events to Send: All Events
Set this as primary: OFF
Exclude card information: ON
```

Guardar con `Create`.

## 19. Disparar eventos reales creando otra subscription

Abrir una tercera terminal. Terminal 3:

```bash
cd ~/undr/yummy/PoC/chargebee
```

Crear otra subscription usando el mismo customer:

```bash
./scripts/04_create_subscription.sh
```

Esto genera una nueva invoice y debería disparar eventos webhooks.

En Terminal 1 deberías ver eventos recibidos, por ejemplo:

```txt
invoice_generated
subscription_created
```

También podés verificar archivos guardados:

```bash
ls -t data/webhook-*.json | head
```

Ver el último webhook:

```bash
ls -t data/webhook-*.json | head -1 | xargs cat
```

Resultado esperado:

```txt
event_type = invoice_generated
invoice.status = payment_due
invoice.id existe
subscription.id existe
```

## 20. Pagar la nueva invoice recibida por webhook

Del webhook o del `04_create_subscription.pretty.json`, copiar:

```txt
invoice.id
subscription.id
```

Editar `.env`:

```bash
nano .env
```

Actualizar:

```txt
INVOICE_ID="NUEVO_INVOICE_ID"
SUBSCRIPTION_ID="NUEVO_SUBSCRIPTION_ID"
```

Registrar pago externo:

```bash
./scripts/07_record_payment.sh
```

Verificar:

```bash
./scripts/06_retrieve_invoice.sh && cat data/06_retrieve_invoice.pretty.json
```

Resultado esperado:

```txt
invoice.status = paid
amount_due = 0
amount_paid = 1000
```

En Terminal 1 deberían llegar nuevos webhooks:

```txt
invoice_updated
payment_succeeded
```

Esto valida el loop completo:

```txt
Chargebee genera invoice
→ webhook llega al backend mock
→ company registra pago externo
→ Chargebee marca invoice paid
→ Chargebee envía payment_succeeded
```

## 21. Prueba opcional de cancelación

Solo hacer esto cuando ya no quieras seguir usando esa subscription.

Verificar que `.env` tenga el `SUBSCRIPTION_ID` correcto.

Importante:

Para Product Catalog 2.0 el script debe usar:

```txt
/subscriptions/{SUBSCRIPTION_ID}/cancel_for_items
```

No usar el endpoint legacy de cancelación o Chargebee devolverá:

```txt
configuration_incompatible
pc2_to_pc1_error
```

Ejecutar:

```bash
./scripts/10_cancel_subscription.sh && cat data/10_cancel_subscription.pretty.json
```

Resultado esperado:

```txt
subscription.status = cancelled
```

También debería llegar webhook de cancelación al receiver si el webhook sigue activo.

## 22. Qué quedó validado

Esta PoC valida:

```txt
1. company puede crear catálogo recurrente en Chargebee vía API.
2. company puede crear customers sin tarjeta.
3. company puede crear subscriptions con auto_collection=off.
4. Chargebee genera invoices recurring payment_due.
5. company puede registrar pagos externos con record_payment.
6. Chargebee marca invoices como paid.
7. Chargebee mantiene subscription active y next_billing_at.
8. Chargebee envía webhooks reales al backend local.
9. El backend puede recibir invoice_generated, subscription_created, invoice_updated, payment_succeeded y subscription_cancelled.
10. El modelo Chargebee billing engine + company external crypto payment rail es viable.
```

## 23. Baches encontrados y correcciones

### Error: `item_family_id cannot be blank`

Solución:

Crear primero Item Family con `00b_create_item_family.sh` y pasar `item_family_id` al crear item.

### Error: Product Catalog 1.0 incompatible con Product Catalog 2.0

Solución:

Usar endpoint PC 2.0:

```txt
/customers/{CUSTOMER_ID}/subscription_for_items
```

No usar endpoint legacy de subscriptions.

### Error creando one-time invoice con plan item price

No se usó para la PoC final. El endpoint de one-time invoice requiere charge item price, no plan item price. Para validar webhooks usamos otra subscription, que es más cercana al flujo real.

### Error cancelando subscription con Product Catalog 2.0

Error:

```txt
configuration_incompatible
pc2_to_pc1_error
```

Solución:

Usar endpoint PC 2.0:

```txt
/subscriptions/{SUBSCRIPTION_ID}/cancel_for_items
```

No usar el endpoint legacy de cancelación.

### `npm install`

No corresponde. Los scripts son bash/curl y el receiver usa Node nativo.

### `ngrok` no instalado / snap no disponible en WSL

Se usó `cloudflared tunnel --url http://localhost:8787`.

## 24. Cierre conceptual

El flujo validado para company es:

```txt
Chargebee = billing engine
company backend = adapter/orchestrator
Smart contract company = autorización y ejecución de pago USDC
Chargebee record_payment = reconciliación del pago externo
```

Chargebee no procesa el dinero. company ejecuta el pago por fuera y Chargebee solo actualiza el estado contable/billing.
