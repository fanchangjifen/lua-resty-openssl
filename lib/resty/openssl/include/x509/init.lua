local ffi = require "ffi"

require "resty.openssl.include.ossl_typ"
require "resty.openssl.include.bio"
require "resty.openssl.include.pem"
require "resty.openssl.include.stack"
local asn1_macro = require "resty.openssl.include.asn1"

local OPENSSL_10 = require("resty.openssl.version").OPENSSL_10
local OPENSSL_11 = require("resty.openssl.version").OPENSSL_11

ffi.cdef [[
  // STACK_OF(X509)
  OPENSSL_STACK *X509_chain_up_ref(OPENSSL_STACK *chain);

  typedef struct X509_extension_st X509_EXTENSION;

  int X509_sign(X509 *x, EVP_PKEY *pkey, const EVP_MD *md);

  ASN1_TIME *X509_gmtime_adj(ASN1_TIME *s, long adj);

  int X509_add_ext(X509 *x, X509_EXTENSION *ex, int loc);
  X509_EXTENSION *X509_get_ext(const X509 *x, int loc);
  int X509_get_ext_by_NID(const X509 *x, int nid, int lastpos);
  void *X509_get_ext_d2i(const X509 *x, int nid, int *crit, int *idx);

  int X509_EXTENSION_set_critical(X509_EXTENSION *ex, int crit);
  int X509_EXTENSION_get_critical(const X509_EXTENSION *ex);
  ASN1_OBJECT *X509_EXTENSION_get_object(X509_EXTENSION *ex);
  ASN1_OCTET_STRING *X509_EXTENSION_get_data(X509_EXTENSION *ne);

  // needed by pkey
  EVP_PKEY *d2i_PrivateKey_bio(BIO *bp, EVP_PKEY **a);
  EVP_PKEY *d2i_PUBKEY_bio(BIO *bp, EVP_PKEY **a);

  int X509_set_pubkey(X509 *x, EVP_PKEY *pkey);
  int X509_set_version(X509 *x, long version);
  int X509_set_serialNumber(X509 *x, ASN1_INTEGER *serial);
  int X509_set_subject_name(X509 *x, X509_NAME *name);
  int X509_set_issuer_name(X509 *x, X509_NAME *name);

  int X509_pubkey_digest(const X509 *data, const EVP_MD *type,
                       unsigned char *md, unsigned int *len);
  int X509_digest(const X509 *data, const EVP_MD *type,
                unsigned char *md, unsigned int *len);

  const char *X509_verify_cert_error_string(long n);
  int X509_verify_cert(X509_STORE_CTX *ctx);
]]

asn1_macro.declare_asn1_functions("X509")
asn1_macro.declare_asn1_functions("X509_EXTENSION")

if OPENSSL_11 then
  ffi.cdef [[
    int X509_set1_notBefore(X509 *x, const ASN1_TIME *tm);
    int X509_set1_notAfter(X509 *x, const ASN1_TIME *tm);
    /*const*/ ASN1_TIME *X509_get0_notBefore(const X509 *x);
    /*const*/ ASN1_TIME *X509_get0_notAfter(const X509 *x);
    EVP_PKEY *X509_get_pubkey(X509 *x);
    long X509_get_version(const X509 *x);
    const ASN1_INTEGER *X509_get0_serialNumber(X509 *x);
    X509_NAME *X509_get_subject_name(const X509 *a);
    X509_NAME *X509_get_issuer_name(const X509 *a);

    X509_EXTENSION *X509_delete_ext(X509 *x, int loc);
  ]]
elseif OPENSSL_10 then
  -- in openssl 1.0.x some getters are direct accessor to struct members (defiend by macros)
  ffi.cdef [[
    // crypto/x509/x509.h
    typedef struct X509_val_st {
      ASN1_TIME *notBefore;
      ASN1_TIME *notAfter;
    } X509_VAL;
    // Note: this struct is trimmed
    typedef struct x509_cinf_st {
      /*ASN1_INTEGER*/ void *version;
      /*ASN1_INTEGER*/ void *serialNumber;
      /*X509_ALGOR*/ void *signature;
      /*X509_NAME*/ void *issuer;
      X509_VAL *validity;
      X509_NAME *subject;
      /*X509_PUBKEY*/ void *key;
      /*ASN1_BIT_STRING*/ void *issuerUID; /* [ 1 ] optional in v2 */
      /*ASN1_BIT_STRING*/ void *subjectUID; /* [ 2 ] optional in v2 */
      /*STACK_OF(X509_EXTENSION)*/ OPENSSL_STACK *extensions; /* [ 3 ] optional in v3 */
      // trimmed
      // ASN1_ENCODING enc;
    } X509_CINF;
    // Note: this struct is trimmed
    struct x509_st {
      X509_CINF *cert_info;
      // trimmed
    } X509;

    int X509_set_notBefore(X509 *x, const ASN1_TIME *tm);
    int X509_set_notAfter(X509 *x, const ASN1_TIME *tm);
    EVP_PKEY *X509_get_pubkey(X509 *x);
    ASN1_INTEGER *X509_get_serialNumber(X509 *x);
    X509_NAME *X509_get_subject_name(const X509 *a);
    X509_NAME *X509_get_issuer_name(const X509 *a);

    // STACK_OF(X509_EXTENSION)
    X509_EXTENSION *X509v3_delete_ext(OPENSSL_STACK *x, int loc);
  ]]
end
