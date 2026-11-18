# Plan

Related work: DS-14399, PR 113. Add input validation at the root and child module, retaining the existing `any` interface and heterogeneous tuple support. Verify malformed scalar, map and missing job name failures and the existing valid heterogeneous cases with Terraform tests. No provider, upstream, or default change is planned. Existing consumers relying on silently ignored malformed inputs will instead receive a clear error. No net-new provider capability is introduced. Rollback: revert the validation change. Existing feature packages do not cover this scrape input behavior.
