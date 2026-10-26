sed "s/@HEAD@/$(git rev-parse HEAD)/" HANDOFF.in > HANDOFF.md && rm HANDOFF.in
