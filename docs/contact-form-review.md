# Contact form assessment

## Decision

Use a dedicated, accessible contact page with a real HTML form, visible labels,
native input constraints, and a LinkedIn alternative. The owner requested
placeholders for delivery configuration, so the form and submit button remain
disabled. No submission is sent or stored. The page makes this explicit.

For a small static portfolio, a hosted form endpoint with inbox notification and
abuse protection is the simplest option to operate. Evaluate its privacy,
retention, spam controls, accessibility, and delivery before selecting a provider.
An AWS backend is reasonable as an operations project if its deployment, monitoring,
delivery, retention, and recovery are intentionally maintained. A mailto form is
not a substitute for confirmed delivery and depends on the visitor's email setup.

## Existing implementation findings

Reviewed the existing contact frontend and
[contact-form.yaml](../infrastructure/cloudformation/contact-form.yaml).
No cloud resources were deployed or changed.

- The frontend API URL and CSP origin are placeholders; delivery is not configured.
- The frontend uses a div with placeholder-only inputs rather than a labeled form.
  The custom modal lacks focus trapping and restoration.
- The backend creates an API Gateway V2 HTTP API, then attempts a WAF WebACL
  association to its stage. CloudFormation documents API Gateway **REST API**
  stages as supported resources for that association. The current HTTP API
  association should not be treated as deployable WAF protection.
- The Lambda stores messages in DynamoDB but defines no email notification or
  operator inbox workflow. A successful write does not mean the owner was notified.
- Valid JSON that is not an object reaches body.get and can fail. Values are
  coerced and truncated rather than strictly type/size validated.
- The frontend does not obtain a reCAPTCHA token; enabling the backend secret
  without completing the client integration rejects legitimate submissions.
- reCAPTCHA verification checks success and score but not expected action and
  hostname. Review these checks if retaining reCAPTCHA.
- Fixed resource names retain legacy naming and can collide across deployments.
- Message bodies and IP addresses are retained in the table. TTL cleanup is
  asynchronous; retention wording must not promise exact deletion at 90 days.
- Log handling, delivery failure alerts, notification retries, and recovery
  evidence need to be designed before production use.

Sources:
- [AWS WebACLAssociation supported resource types](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-wafv2-webaclassociation.html)
- [DynamoDB TTL behavior](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html)
- [reCAPTCHA v3 verification](https://developers.google.com/recaptcha/docs/v3)

## Activation requirements

1. Replace the receiver and endpoint placeholders with the owner's chosen service.
2. Define notification delivery, server-side type and length validation, abuse
   controls, minimal retention, and a short visitor-facing privacy explanation.
3. Allow only the chosen endpoint in CSP form-action (and connect-src if using
   fetch). Never put service secrets in public HTML or JavaScript.
4. Enable form controls only after testing in a non-production environment.
   Use clear pending, success, failure, and retry states without discarding
   visitor input on a failed request. Provide a non-JavaScript path if practical.
5. Test invalid email, empty/oversized messages, malformed requests, rate limits,
   service failure, keyboard navigation, mobile layout, and confirmed delivery.
   Sending a test message requires explicit authorization.
6. If AWS is selected, repair and validate the infrastructure separately, review
   the change set and costs, and record rollback and recovery procedures.

To revert an activation, restore the disabled form and restrictive CSP and
redeploy the site. Handle previously collected data under the chosen retention
policy; disabling the frontend does not delete server-side records.
