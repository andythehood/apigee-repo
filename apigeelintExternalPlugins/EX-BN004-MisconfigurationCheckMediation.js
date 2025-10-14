/*
  Copyright 2023 Google LLC

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

const plugin = {
    ruleId: "EX-BN004",
    name: "Require Specific Policy Types in PreFlow Request for each Endpoint.",
    message: "Require one or more specific policies be used in the PreFlow.",
    fatal: false,
    severity: 1, // error, 1=warning
    nodeType: "ProxyEndpoint",
    enabled: true,
  },
  policyMap = new Map(),
  requiredPolicyTypes = ["OASValidation", "MessageValidation"],
  requireAll = true; // false=requireAtLeastOne

const onBundle = function (bundle, cb) {
  bundle.getPolicies().forEach(function (p) {
    policyMap.set(p.getName(), p.getType());
  });

  if (typeof cb == "function") {
    cb(null, false);
  }
};

const onProxyEndpoint = function (ep, cb) {
  const proxyName = ep.getName();
  const missingPolicyTypes = [],
    preFlowSteps = [];
  ep.getPreFlow() &&
    ep.getPreFlow().getFlowRequest() &&
    ep
      .getPreFlow()
      .getFlowRequest()
      .getSteps()
      .forEach(function (step) {
        const policyType = policyMap.get(step.getName());

        preFlowSteps.push(policyType);
      });

  requiredPolicyTypes.forEach((s) => {
    if (!preFlowSteps.includes(s)) {
      missingPolicyTypes.push(s);
    }
  });

  let warnErr = requireAll
    ? missingPolicyTypes.length > 0
      ? true
      : false
    : missingPolicyTypes.length == requiredPolicyTypes.length
    ? true
    : false;
  if (warnErr) {
    ep.addMessage({
      plugin,
      message:
        'ProxyEndpoint named: "' +
        proxyName +
        '" requires ' +
        (requireAll
          ? 'all of the policy types: "'
          : 'at least one of the policy types: "') +
        requiredPolicyTypes +
        '" but is missing policy types: "' +
        missingPolicyTypes +
        '"',
    });
    warnErr = true;
  }
  if (typeof cb == "function") {
    cb(null, warnErr);
  }
};

module.exports = {
  plugin,
  onBundle,
  onProxyEndpoint,
};
