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
    ruleId: "EX-PF001",
    name: "Require Named Policies in PreFlow Request.",
    message: "Require one or more specific policies be used in the PreFlow.",
    fatal: false,
    severity: 2, // error, 1=warning
    nodeType: "ProxyEndpoint",
    enabled: true,
  },
  requiredPolicies = ["VA-header", "AM-remove-x-apikey", "FC-security"];

const onProxyEndpoint = function (ep, cb) {
  const proxyName = ep.getName();
  const missingPolicies = [],
    preFlowSteps = [];
  ep.getPreFlow() &&
    ep.getPreFlow().getFlowRequest() &&
    ep
      .getPreFlow()
      .getFlowRequest()
      .getSteps()
      .forEach(function (step) {
        preFlowSteps.push(step.getName());
      });

  requiredPolicies.forEach((s) => {
    if (!preFlowSteps.includes(s)) {
      missingPolicies.push(s);
    }
  });

  let warnErr = missingPolicies.length > 0 ? true : false;
  if (warnErr) {
    ep.addMessage({
      plugin,
      message:
        'ProxyEndpoint named: "' +
        proxyName +
        '" requires policies: "' +
        requiredPolicies +
        '" but is missing policies: "' +
        missingPolicies +
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
  onProxyEndpoint,
};
