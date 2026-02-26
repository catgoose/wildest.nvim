#ifndef MILDER_FUZZY_H
#define MILDER_FUZZY_H

#include <stdbool.h>

bool fuzzy_has_match(const char *needle, const char *haystack);
double fuzzy_score(const char *needle, const char *haystack);
int fuzzy_filter_sort(
    const char *needle,
    const char **candidates, int num_candidates,
    int *out_indices, double *out_scores, int *out_count
);
int fuzzy_positions(
    const char *needle, const char *haystack,
    int *out_positions, int *out_count
);

#endif
