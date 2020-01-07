/* assert.h
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

#pragma once

#include <glib.h>

typedef enum    e_AssertionError
{
    ASSERTION_ERROR_ASSERT_ERROR
}               AssertionError;

#define ASSERTION_ERROR assertion_error_quark()
#define PROTON_ASSERT_(expr, err) \
    proton_assert_((expr), "Assertion " #expr " failed", err)

GQuark      assertion_error_quark(void);
gboolean    proton_assert_(gboolean expr, gchar *msg, GError **error);
