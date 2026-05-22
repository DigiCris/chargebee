# Chargebee POC - Luca recurring crypto payments

Objetivo: validar con `curl` que Chargebee puede funcionar como billing engine externo mientras Luca ejecuta el pago crypto fuera de Chargebee.

## Qué API key usar

Usá la `full_access_key_v1` / `Full-Access`, no la `publishable_api_key_1`.

La publishable key es para frontend/checkout público. Para crear customers, plans, subscriptions y hacer `record_payment` necesitás la Full-Access key.

## Configuración inicial

Desde esta carpeta:

```bash
cp .env.example .env
```

Editá `.env` y poné:

```bash
CHARGEBEE_SITE="comuynt-test"
CHARGEBEE_API_KEY="test_G9...TU_FULL_ACCESS_KEY"
```

Podés cambiar nombres/ids como `ITEM_ID`, `ITEM_PRICE_ID`, `CUSTOMER_ID`, etc.

## Paso a paso

### 1) Probar auth

```bash
./scripts/00_check_auth.sh
```

Check: debe devolver JSON sin `api_error_code`.

### 2) Crear plan item

```bash
./scripts/01_create_item.sh
```

Check en Chargebee: Product Catalog debe mostrar el item/plan creado.

### 3) Crear precio mensual

```bash
./scripts/02_create_item_price.sh
```

Check: debe crear un precio mensual por `PRICE_CENTS`. Recordá: `1000 = USD 10.00`.

### 4) Crear customer

```bash
./scripts/03_create_customer.sh
```

Check: Customers debe mostrar el customer. Importante: `auto_collection=off`.

### 5) Crear subscription

```bash
./scripts/04_create_subscription.sh
```

Check: Subscriptions debe mostrar la subscription. Abrí `data/04_create_subscription.pretty.json` y copiá:

- `subscription.id` → `SUBSCRIPTION_ID` en `.env`
- `invoice.id` si aparece → `INVOICE_ID` en `.env`

Si no aparece invoice en la respuesta, seguí con el paso 6.

### 6) Buscar invoice pendiente

```bash
./scripts/05_list_due_invoices.sh
```

Check: buscá una invoice con `status = payment_due`. Copiá su `id` en `INVOICE_ID` dentro de `.env`.

### 7) Ver invoice antes del pago

```bash
./scripts/06_retrieve_invoice.sh
```

Check: debe estar `payment_due`, `posted` o `not_paid`, con `amount_due > 0`.

### 8) Simular pago crypto exitoso y registrar pago externo

```bash
./scripts/07_record_payment.sh
```

Check: la invoice debería bajar `amount_due`. Si el monto cubre todo, debería quedar `paid`.

### 9) Confirmar invoice pagada

```bash
./scripts/06_retrieve_invoice.sh
```

Check: invoice `status = paid`.

### 10) Revisar subscription

```bash
./scripts/08_retrieve_subscription.sh
```

Check: la subscription debe seguir activa y Chargebee debe conservar su lifecycle.

## Webhook opcional

Para validar que Chargebee puede llamar a un endpoint de Luca:

```bash
node scripts/09_mock_webhook_receiver.mjs
```

En otra terminal exponé local con ngrok/cloudflared. Ejemplo con ngrok:

```bash
ngrok http 8787
```

En Chargebee: Configure Chargebee → API Keys and Events → Webhooks → Add Webhook.

URL:

```txt
https://TU-TUNNEL/chargebee/webhook
```

Check: cuando Chargebee emita eventos, el script guarda archivos en `data/webhook-*.json`.

## Qué valida esta PoC

- Luca puede crear catálogo mínimo vía API.
- Luca puede crear customer y subscription vía API.
- Chargebee puede generar invoices sin payment method tradicional usando `auto_collection=off`.
- Luca puede simular pago crypto y registrar el pago con `record_payment`.
- Chargebee puede marcar invoice como paid y continuar siendo el billing source of truth.

## Qué NO valida todavía

- Smart contract real.
- Mandates onchain.
- Batch execution.
- Seguridad de reauthorization/pricing changes.
- Backend real de Luca.

