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
    ruleId: "EX-PF002",
    name: "Require Shared Flow PreFlow Request.",
    message:
      "Require Flow Callout policy with specific Shared Flow reference in PreFlow Request.",
    fatal: true,
    severity: 2, // error, 1=warning
    nodeType: "Bundle",
    enabled: true,
  },
  // xpath = require("xpath"),
  policyMap = new Map(),
  requiredSharedFlows = ["security-v1", "SF-SpikeArrest"];

const onBundle = function (bundle, cb) {
  bundle.getPolicies().forEach(function (p) {
    if (p.getType() == "FlowCallout") {
      // the following code avoids the use of xpath() npm module, which is not resolvable if the
      // externalPlugins directory is outside of the apigeelint directory

      let i1 = p.getElement().toString().indexOf("<SharedFlowBundle>");
      let i2 = p.getElement().toString().indexOf("</SharedFlowBundle>");
      let sharedFlowName = p
        .getElement()
        .toString()
        .substring(i1 + "<SharedFlowBundle>".length, i2)
        .trim();

      policyMap.set(sharedFlowName, p.getName());
    }
  });

  if (typeof cb == "function") {
    cb(null, false);
  }
};

const onProxyEndpoint = function (ep, cb) {
  const proxyName = ep.getName();
  const missingSharedFlows = [],
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

  requiredSharedFlows.forEach((sf) => {
    // debug("forEach SF: " + sf + " " + policyMap.get(sf));
    if (!policyMap.has(sf)) {
      missingSharedFlows.push(sf);
    }
  });

  let warnErr = missingSharedFlows.length > 0 ? true : false;
  if (warnErr) {
    ep.addMessage({
      plugin,
      message:
        'ProxyEndpoint named: "' +
        proxyName +
        '" requires Shared Flow usage for: "' +
        requiredSharedFlows +
        '" but is missing Shared Flows: "' +
        missingSharedFlows +
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
