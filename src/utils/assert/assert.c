/* assert.c
 *
 * Copyright 2020 Paulo Queiroz <pvaqueiroz@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "assert.h"

#define ASSERTION_ERROR assertion_error_quark()

GQuark      assertion_error_quark(void)
{
    return g_quark_from_static_string("assertion-error-quark");
}

gboolean    proton_assert_(gboolean expr, gchar *msg, GError **error)
{
    GError  *err;

    if (!expr)
    {
        err = g_error_new_literal(ASSERTION_ERROR,
                                  ASSERTION_ERROR_ASSERT_ERROR,
                                  msg);
        g_propagate_error(error, err);
        return (FALSE);
    }
    return (TRUE);
}
