/**
 * Copyright: Copyright (c) 2016 Wojciech Szęszoł. All rights reserved.
 * Authors: Wojciech Szęszoł
 * Version: Initial created: May 26, 2016
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dstep.translator.TypedefIndex;

import clang.c.Index;
import clang.Cursor;
import clang.TranslationUnit;


class TypedefIndex
{
    import std.typecons: Flag, No;

    private Cursor[Cursor] typedefs;

    this(TranslationUnit translUnit)
    {
        this(translUnit, (ref const(Cursor)) => false);
    }

    this(TranslationUnit translUnit, bool function(ref const(Cursor)) isWantedCursor)
    {
        import std.functional: toDelegate;
        this(translUnit, isWantedCursor.toDelegate);
    }

    this(TranslationUnit translUnit, bool delegate(ref const(Cursor)) isWantedCursor)
    {
        bool[Cursor] visited;

        auto file = translUnit.file;

        foreach (cursor; translUnit.cursor.all)
        {
            if (cursor.file == file || (isWantedCursor !is null && isWantedCursor(cursor)))
            {
                visited[cursor] = true;
                inspect(cursor, visited);
            }
        }
    }

    private void inspect(Cursor cursor, bool[Cursor] visited)
    {
        if (cursor.kind == CXCursorKind.typedefDecl)
        {
            foreach (child; cursor.all)
            {
                if (child.kind == CXCursorKind.typeRef
                    || child.isDeclaration)
                {
                    if (child.referenced !in typedefs)
                    {
                        typedefs[child.referenced] = cursor;
                        typedefs[child.referenced.canonical] = cursor;
                    }
                }
            }
        }
        else if ((cursor in visited) is null)
        {
            foreach (child; cursor.all)
            {
                visited[cursor] = true;
                inspect(cursor, visited);
            }
        }
    }

    Cursor typedefParent(in Cursor cursor)
    {
        auto result = cursor in typedefs;

        if (result is null)
            return cursor.empty;
        else
            return *result;
    }
}
