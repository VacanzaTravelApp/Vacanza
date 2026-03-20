package com.vacanza.backend.repo;

import com.vacanza.backend.entity.LevelDefinition;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface LevelDefinitionRepository extends JpaRepository<LevelDefinition, Integer> {

    /**
     * Find the highest level that the given XP qualifies for.
     * E.g. if xp=350 and levels are 0→L1, 100→L2, 300→L3, 600→L4 → returns L3.
     */
    Optional<LevelDefinition> findTopByMinXpLessThanEqualOrderByMinXpDesc(int xp);

    /**
     * Find the next level above the given XP.
     * Used to calculate "XP to next level".
     */
    Optional<LevelDefinition> findTopByMinXpGreaterThanOrderByMinXpAsc(int xp);
}
