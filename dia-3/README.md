# Entregable semana 4 — Stellar Elite Bolivia

Implementación sobre `dia-3` del repositorio del bootcamp.

## Regla de inversión

Cada llamada a `invest` debe tener `payment_amount >= 500`. La función
`check_variation_gate` recibe el monto y devuelve `Error::AmountTooLow` (código 7)
si es menor. La comprobación ocurre antes del pago y de la emisión de RWA.

El test `test_minimum_investment_100_fails_and_500_succeeds` demuestra que:

- 100 falla específicamente con `AmountTooLow` sin cambiar los balances.
- 499 también falla y exactamente 500 funciona.
- Con `price_per_unit = 100`, invertir 500 emite 5 unidades de RWA.
- Una inversión posterior de 100 sigue fallando: el mínimo es por operación.

Los tests existentes de whitelist y retiro también se conservan.

```bash
cd dia-3
cargo test --locked
stellar contract build
```

## Unidades y token de pago

Se conserva la convención del código y de los tests del bootcamp: **100 y 500
son los enteros enviados a `payment_amount`**, en unidades mínimas del token.
No se multiplican por decimales dentro de la regla.

Para esta demostración se usa el SAC de XLM de **Testnet**, financiado con
Friendbot, como token de pago elegido para esta entrega. XLM tiene
7 decimales: 100 unidades mínimas son 0.0000100 XLM y 500 son 0.0000500 XLM.
No se utilizan fondos de Mainnet. Para usar el token del profesor, cambiar
`PAYMENT_TOKEN` al inicializar un nuevo contrato y financiar al inversor con él.

## Flujo reproducible con los scripts del repo

Requisitos: Rust con `wasm32v1-none`, Stellar CLI y dos cuentas de Testnet.
Los alias guardan las claves localmente en Stellar CLI; no subir claves secretas.

```bash
stellar keys generate stellar-elite-week4-admin --network testnet --fund
stellar keys generate stellar-elite-week4-investor --network testnet --fund

stellar contract build
stellar contract deploy \
  --wasm target/wasm32v1-none/release/rwa_launchpad_dia_3.wasm \
  --source stellar-elite-week4-admin --network testnet

cp .env.example .env.local
# Completar CONTRACT_ID con la salida del deploy.
# PAYMENT_TOKEN: stellar contract id asset --asset native --network testnet
# INVESTOR: stellar keys address stellar-elite-week4-investor
source .env.local

bash scripts/admin-tool.sh setup
bash scripts/user-tool.sh demo
```

`admin-tool.sh setup` inicializa una sola vez y agrega al inversor a la whitelist.
`user-tool.sh demo` verifica el rechazo de 100, invierte 500 y comprueba que el
balance aumenta en 5 RWA. Si el error no es el esperado o el saldo no coincide,
el script termina con error.

El intento de 100 es rechazado durante la simulación del CLI; **no se envía una
transacción fallida a la red**. La inversión de 500 sí se firma, envía y confirma.
El enlace de Stellar Expert corresponde a esa inversión exitosa.

Se conservaron las operaciones opcionales de los scripts como subcomandos:
`mint`, `withdraw`, `pause`, `unpause` y `transfer`. No se ejecutan en la demo
porque alterarían el saldo que se quiere demostrar. Cada repetición de `demo`
aumenta el balance en 5 RWA; `setup` no debe repetirse sobre un contrato inicializado.

## Entrega

Los identificadores, transacción y capturas de esta ejecución están en
[ENTREGA.md](ENTREGA.md) y los registros originales en [evidence/](evidence/).
La rúbrica actual permite capturas o un video de máximo **2 minutos**; tiene
prioridad sobre el antiguo checklist de 3 minutos del repositorio base.

## Alcance

Ejercicio educativo de Testnet. El cambio se centra en la regla solicitada y
sus pruebas; no es una auditoría del launchpad base. En particular, el código
base autoriza el parámetro `admin` sin compararlo con el administrador almacenado.
No utilizar este ejemplo para custodiar fondos reales sin corregir y revisar
sus controles de acceso y demás invariantes.
