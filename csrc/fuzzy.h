#ifndef WILDEST_FUZZY_H
#define WILDEST_FUZZY_H

#include <stdbool.h>

/*
 * fuzzy_has_match — check if needle is a fuzzy subsequence of haystack.
 *
 * @param needle   Search string (case-insensitive). NULL or "" returns false/true respectively.
 * @param haystack String to search within. NULL returns false.
 * @return         true if every character in needle appears in haystack in order.
 */
bool fuzzy_has_match(const char *needle, const char *haystack);

/*
 * fuzzy_score — compute a fuzzy match score for needle in haystack.
 *
 * Higher scores indicate better matches. Returns SCORE_MAX (1e9) for exact
 * matches and SCORE_MIN (-1e9) on error, empty needle, or oversized input.
 *
 * Limits: needle up to 1024 chars, haystack up to 8192 chars.
 *
 * @param needle   Search string (case-insensitive).
 * @param haystack String to score against.
 * @return         Match score (higher is better), or -1e9 on error.
 */
double fuzzy_score(const char *needle, const char *haystack);

/*
 * fuzzy_filter_sort — batch filter and sort candidates by fuzzy match score.
 *
 * Filters candidates that match needle, scores them, and sorts descending.
 * When needle is empty, all candidates are returned with score 0.
 *
 * @param needle         Search string (case-insensitive).
 * @param candidates     Array of candidate strings.
 * @param num_candidates Length of the candidates array.
 * @param out_indices    Output: original indices of matching candidates (caller-allocated, size >= num_candidates).
 * @param out_scores     Output: scores of matching candidates (caller-allocated, size >= num_candidates).
 * @param out_count      Output: number of matches written.
 * @return               0 on success, -1 on error (NULL args or allocation failure).
 */
int fuzzy_filter_sort(
    const char *needle,
    const char **candidates, int num_candidates,
    int *out_indices, double *out_scores, int *out_count
);

/*
 * fuzzy_positions — extract matched character positions for highlighting.
 *
 * Computes the DP matrices and traces back to find the best position for
 * each needle character within haystack.
 *
 * Limits: needle up to 1024 chars, haystack up to 8192 chars.
 *
 * @param needle        Search string (case-insensitive).
 * @param haystack      String to match against.
 * @param out_positions Output: 0-indexed byte positions (caller-allocated, size >= strlen(needle)).
 * @param out_count     Output: number of positions written (== strlen(needle) on success).
 * @return              0 on success, -1 on error (NULL args, oversized input, or allocation failure).
 */
int fuzzy_positions(
    const char *needle, const char *haystack,
    int *out_positions, int *out_count
);

#endif
