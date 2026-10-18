/**
 * PayPal + web unlock (codes are emailed by the backend — not listed here).
 * Redeploy: DEPLOY_WEB_APP=0 ./website/deploy-web.sh  (or full release)
 */
window.ADHAN_PAYPAL = {
  appName: 'Adhan App (Web)',
  priceLabel: '$4.99 USD',
  currency: 'USD',
  amount: '4.99',

  paypalMeUrl: 'https://paypal.me/innovatorgeneration/4.99',
  hostedButtonId: '',
  clientId: '',

  /** Backend that emails + verifies unlock codes */
  apiBase: 'https://api.mywaitime.com/adhan-api',

  contactEmail: 'zub165@yahoo.com',
  storageKey: 'adhan_web_paid_v1',
  appPath: '/adhan/app/',
};
