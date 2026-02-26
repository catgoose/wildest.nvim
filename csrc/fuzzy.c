/*
 * wildest fuzzy matching — fzy-inspired scoring algorithm
 *
 * Based on the fzy algorithm by John Googin (Smith-Waterman-like DP).
 * Provides: has_match, score, batch filter+sort, position extraction.
 */

#include "fuzzy.h"
#include <ctype.h>
#include <float.h>
#include <stdlib.h>
#include <string.h>

/* Scoring constants */
#define SCORE_MIN       (-1e9)
#define SCORE_MAX       (1e9)
#define SCORE_GAP_LEADING   (-0.005)
#define SCORE_GAP_TRAILING  (-0.005)
#define SCORE_GAP_INNER     (-0.01)
#define SCORE_MATCH_CONSECUTIVE (1.0)
#define SCORE_MATCH_SLASH       (0.9)
#define SCORE_MATCH_WORD        (0.8)
#define SCORE_MATCH_CAPITAL     (0.7)
#define SCORE_MATCH_DOT         (0.6)

#define MAX_NEEDLE_LEN  128
#define MAX_HAYSTACK_LEN 1024

/* Case-insensitive char comparison */
static inline bool chars_match(char a, char b) {
    return tolower((unsigned char)a) == tolower((unsigned char)b);
}

/* Classify boundary bonus for position in haystack */
static double compute_bonus(const char *haystack, int i) {
    if (i == 0)
        return SCORE_MATCH_SLASH; /* start of string is like after separator */

    char prev = haystack[i - 1];
    char cur = haystack[i];

    if (prev == '/' || prev == '\\')
        return SCORE_MATCH_SLASH;
    if (prev == '-' || prev == '_' || prev == ' ')
        return SCORE_MATCH_WORD;
    if (prev == '.')
        return SCORE_MATCH_DOT;
    if (islower((unsigned char)prev) && isupper((unsigned char)cur))
        return SCORE_MATCH_CAPITAL;

    return 0.0;
}

bool fuzzy_has_match(const char *needle, const char *haystack) {
    if (!needle || !haystack)
        return false;
    if (needle[0] == '\0')
        return true;

    const char *np = needle;
    const char *hp = haystack;

    while (*np && *hp) {
        if (chars_match(*np, *hp))
            np++;
        hp++;
    }

    return *np == '\0';
}

double fuzzy_score(const char *needle, const char *haystack) {
    int n = (int)strlen(needle);
    int m = (int)strlen(haystack);

    if (n == 0)
        return SCORE_MIN;
    if (n == m) {
        /* Exact length match — check if exact match */
        bool exact = true;
        for (int i = 0; i < n; i++) {
            if (!chars_match(needle[i], haystack[i])) {
                exact = false;
                break;
            }
        }
        if (exact)
            return SCORE_MAX;
    }
    if (n > MAX_NEEDLE_LEN || m > MAX_HAYSTACK_LEN)
        return SCORE_MIN;

    /*
     * DP matrices (stack-allocated for performance):
     * D[i][j] = best score ending with needle[i] matching haystack[j] (consecutive)
     * M[i][j] = best score for needle[0..i] matching in haystack[0..j]
     */
    double D[MAX_NEEDLE_LEN][MAX_HAYSTACK_LEN];
    double M[MAX_NEEDLE_LEN][MAX_HAYSTACK_LEN];

    /* Precompute bonuses */
    double bonus[MAX_HAYSTACK_LEN];
    for (int j = 0; j < m; j++)
        bonus[j] = compute_bonus(haystack, j);

    for (int i = 0; i < n; i++) {
        double prev_score = SCORE_MIN;
        double gap_score = (i == n - 1) ? SCORE_GAP_TRAILING : SCORE_GAP_INNER;

        for (int j = 0; j < m; j++) {
            if (chars_match(needle[i], haystack[j])) {
                double score = SCORE_MIN;

                if (i == 0) {
                    score = j * SCORE_GAP_LEADING + bonus[j];
                } else if (j > 0) {
                    double consecutive = D[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE;
                    double non_consecutive = M[i - 1][j - 1] + bonus[j];
                    score = (consecutive > non_consecutive) ? consecutive : non_consecutive;
                }

                D[i][j] = score;
                M[i][j] = (score > prev_score + gap_score) ? score : prev_score + gap_score;
            } else {
                D[i][j] = SCORE_MIN;
                M[i][j] = prev_score + gap_score;
            }

            prev_score = M[i][j];
        }
    }

    return M[n - 1][m - 1];
}

/* Comparison for qsort: descending by score */
typedef struct {
    int index;
    double score;
} scored_entry_t;

static int compare_scored(const void *a, const void *b) {
    double sa = ((const scored_entry_t *)a)->score;
    double sb = ((const scored_entry_t *)b)->score;
    if (sb > sa) return 1;
    if (sb < sa) return -1;
    return 0;
}

int fuzzy_filter_sort(
    const char *needle,
    const char **candidates, int num_candidates,
    int *out_indices, double *out_scores, int *out_count
) {
    if (!needle || !candidates || !out_indices || !out_scores || !out_count)
        return -1;

    scored_entry_t *entries = (scored_entry_t *)malloc(
        (size_t)num_candidates * sizeof(scored_entry_t)
    );
    if (!entries)
        return -1;

    int count = 0;

    /* Empty needle: return all candidates with score 0 (original order) */
    if (needle[0] == '\0') {
        for (int i = 0; i < num_candidates; i++) {
            entries[count].index = i;
            entries[count].score = 0.0;
            count++;
        }
    } else {
        for (int i = 0; i < num_candidates; i++) {
            if (fuzzy_has_match(needle, candidates[i])) {
                double score = fuzzy_score(needle, candidates[i]);
                entries[count].index = i;
                entries[count].score = score;
                count++;
            }
        }

        qsort(entries, (size_t)count, sizeof(scored_entry_t), compare_scored);
    }

    for (int i = 0; i < count; i++) {
        out_indices[i] = entries[i].index;
        out_scores[i] = entries[i].score;
    }

    *out_count = count;
    free(entries);
    return 0;
}

int fuzzy_positions(
    const char *needle, const char *haystack,
    int *out_positions, int *out_count
) {
    if (!needle || !haystack || !out_positions || !out_count)
        return -1;

    int n = (int)strlen(needle);
    int m = (int)strlen(haystack);

    if (n == 0 || m == 0) {
        *out_count = 0;
        return 0;
    }
    if (n > MAX_NEEDLE_LEN || m > MAX_HAYSTACK_LEN) {
        *out_count = 0;
        return -1;
    }

    /* Recompute DP to trace back positions */
    double D[MAX_NEEDLE_LEN][MAX_HAYSTACK_LEN];
    double M[MAX_NEEDLE_LEN][MAX_HAYSTACK_LEN];

    double bonus[MAX_HAYSTACK_LEN];
    for (int j = 0; j < m; j++)
        bonus[j] = compute_bonus(haystack, j);

    for (int i = 0; i < n; i++) {
        double prev_score = SCORE_MIN;
        double gap_score = (i == n - 1) ? SCORE_GAP_TRAILING : SCORE_GAP_INNER;

        for (int j = 0; j < m; j++) {
            if (chars_match(needle[i], haystack[j])) {
                double score = SCORE_MIN;
                if (i == 0) {
                    score = j * SCORE_GAP_LEADING + bonus[j];
                } else if (j > 0) {
                    double consecutive = D[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE;
                    double non_consecutive = M[i - 1][j - 1] + bonus[j];
                    score = (consecutive > non_consecutive) ? consecutive : non_consecutive;
                }
                D[i][j] = score;
                M[i][j] = (score > prev_score + gap_score) ? score : prev_score + gap_score;
            } else {
                D[i][j] = SCORE_MIN;
                M[i][j] = prev_score + gap_score;
            }
            prev_score = M[i][j];
        }
    }

    /* Traceback: from M[n-1][best_j], walk backwards */
    int positions[MAX_NEEDLE_LEN];
    int i = n - 1;

    /* Find best ending column */
    int best_j = 0;
    for (int j = 1; j < m; j++) {
        if (M[i][j] > M[i][best_j])
            best_j = j;
    }

    positions[i] = best_j;

    /* Trace back each needle char */
    for (i = n - 2; i >= 0; i--) {
        int max_j = positions[i + 1] - 1;
        /* Find best j for needle[i] among 0..max_j */
        int found = -1;
        for (int j = max_j; j >= 0; j--) {
            if (chars_match(needle[i], haystack[j]) && D[i][j] != SCORE_MIN) {
                if (found == -1 || M[i][j] > M[i][found])
                    found = j;
            }
        }
        positions[i] = found;
    }

    *out_count = n;
    for (int k = 0; k < n; k++)
        out_positions[k] = positions[k];

    return 0;
}
