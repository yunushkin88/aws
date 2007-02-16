------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                          Copyright (C) 2003-2007                         --
--                                  AdaCore                                 --
--                                                                          --
--  This library is free software; you can redistribute it and/or modify    --
--  it under the terms of the GNU General Public License as published by    --
--  the Free Software Foundation; either version 2 of the License, or (at   --
--  your option) any later version.                                         --
--                                                                          --
--  This library is distributed in the hope that it will be useful, but     --
--  WITHOUT ANY WARRANTY; without even the implied warranty of              --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       --
--  General Public License for more details.                                --
--                                                                          --
--  You should have received a copy of the GNU General Public License       --
--  along with this library; if not, write to the Free Software Foundation, --
--  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.          --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the GNU Public License.                                      --
------------------------------------------------------------------------------

package body AWS.Resources.Streams.Memory.ZLib is

   pragma Linker_Options ("-lz");

   procedure Flush (Resource : in out Stream_Type);
   --  Complete compression, flush internal compression buffer to the
   --  memory stream.

   ------------
   -- Append --
   ------------

   procedure Append
     (Resource : in out Stream_Type;
      Buffer   : in     Stream_Element_Array;
      Trim     : in     Boolean := False)
   is
      pragma Unreferenced (Trim);
      --  Ignore the Trim parameter, because stream would be trimmed anyway
      --  in the Flush routine.

      procedure Append (Item : in Stream_Element_Array);
      pragma Inline (Append);

      ------------
      -- Append --
      ------------

      procedure Append (Item : in Stream_Element_Array) is
      begin
         Append (Memory.Stream_Type (Resource), Item);
      end Append;

      procedure Write is new ZL.Write (Append);

   begin
      Write (Resource.Filter, Buffer, ZL.No_Flush);
   end Append;

   -----------
   -- Close --
   -----------

   overriding procedure Close (Resource : in out Stream_Type) is
   begin
      Close (Memory.Stream_Type (Resource));
      ZL.Close (Resource.Filter, Ignore_Error => True);
   end Close;

   ------------------------
   -- Deflate_Initialize --
   ------------------------

   procedure Deflate_Initialize
     (Resource     : in out Stream_Type;
      Level        : in     Compression_Level  := ZL.Default_Compression;
      Strategy     : in     Strategy_Type      := ZL.Default_Strategy;
      Method       : in     Compression_Method := ZL.Deflated;
      Window_Bits  : in     Window_Bits_Type   := ZL.Default_Window_Bits;
      Memory_Level : in     Memory_Level_Type  := ZL.Default_Memory_Level;
      Header       : in     Header_Type        := ZL.Default) is
   begin
      Resource.Flushed := False;

      ZL.Deflate_Init
        (Resource.Filter, Level, Strategy, Method,
         Window_Bits, Memory_Level, Header);
   end Deflate_Initialize;

   -----------
   -- Flush --
   -----------

   procedure Flush (Resource : in out Stream_Type) is
      Flush_Buffer : Stream_Element_Array (1 .. 1_024);
      Last         : Stream_Element_Offset;
   begin
      loop
         ZL.Flush (Resource.Filter, Flush_Buffer, Last, ZL.Finish);

         if Last < Flush_Buffer'Last then
            Append
              (Memory.Stream_Type (Resource),
               Flush_Buffer (1 .. Last),
               Trim => True);

            exit;
         else
            Append (Memory.Stream_Type (Resource), Flush_Buffer);
         end if;
      end loop;

      Resource.Flushed := True;
   end Flush;

   ------------------------
   -- Inflate_Initialize --
   ------------------------

   procedure Inflate_Initialize
     (Resource    : in out Stream_Type;
      Window_Bits : in     Window_Bits_Type := ZL.Default_Window_Bits;
      Header      : in     Header_Type      := ZL.Default) is
   begin
      Resource.Flushed := False;

      ZL.Inflate_Init (Resource.Filter, Window_Bits, Header);
   end Inflate_Initialize;

   ----------
   -- Read --
   ----------

   overriding procedure Read
     (Resource : in out Stream_Type;
      Buffer   :    out Stream_Element_Array;
      Last     :    out Stream_Element_Offset) is
   begin
      if not Resource.Flushed then
         Flush (Resource);
      end if;

      Read (Memory.Stream_Type (Resource), Buffer, Last);
   end Read;

   ----------
   -- Size --
   ----------

   overriding function Size
     (Resource : in Stream_Type) return Stream_Element_Offset is
   begin
      if not Resource.Flushed then
         Flush (Resource.Self.all);
      end if;

      return Size (Memory.Stream_Type (Resource));
   end Size;

end AWS.Resources.Streams.Memory.ZLib;
