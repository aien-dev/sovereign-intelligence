sed "s/@HEAD@/$(git rev-parse --short HEAD)/" HANDOFF.in > HANDOFF.md && rm HANDOFF.in
