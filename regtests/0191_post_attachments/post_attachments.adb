------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                     Copyright (C) 2008-2012, AdaCore                     --
--                                                                          --
--  This is free software;  you can redistribute it  and/or modify it       --
--  under terms of the  GNU General Public License as published  by the     --
--  Free Software  Foundation;  either version 3,  or (at your option) any  --
--  later version.  This software is distributed in the hope  that it will  --
--  be useful, but WITHOUT ANY WARRANTY;  without even the implied warranty --
--  of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU     --
--  General Public License for  more details.                               --
--                                                                          --
--  You should have  received  a copy of the GNU General  Public  License   --
--  distributed  with  this  software;   see  file COPYING3.  If not, go    --
--  to http://www.gnu.org/licenses for a complete copy of the license.      --
------------------------------------------------------------------------------

with Ada.Streams;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Ada.Text_IO;

with AWS.Attachments;
with AWS.Client;
with AWS.Headers;
with AWS.MIME;
with AWS.Net.Log;
with AWS.Parameters;
with AWS.Response;
with AWS.Server.Status;
with AWS.Status;
with AWS.Translator;
with AWS.Utils;

procedure Post_Attachments is

   use Ada;
   use Ada.Streams;
   use AWS;

   --------
   -- CB --
   --------

   function CB (Request : Status.Data) return Response.Data is
      Params  : constant Parameters.List := Status.Parameters (Request);
      Attachs : constant Attachments.List := Status.Attachments (Request);

      procedure Output_A_Name (E : Attachments.Element);

      -------------------
      -- Output_A_Name --
      -------------------

      procedure Output_A_Name (E : Attachments.Element) is
      begin
         Text_IO.Put_Line ("Filename       " & Attachments.Filename (E));
         Text_IO.Put_Line
           ("Local Filename " &
              Strings.Fixed.Translate
              (Attachments.Local_Filename (E),
               Strings.Maps.To_Mapping ("\", "/")));
      end Output_A_Name;

   begin
      Text_IO.Put_Line ("*** ID =" & Parameters.Get (Params, "ID"));
      Text_IO.Put_Line
        ("*** N Attachments = "
           & Natural'Image (Attachments.Count (Attachs)));
      Attachments.Iterate (Attachs, Output_A_Name'Access);
      return Response.Build (MIME.Text_HTML, "ok");
   end CB;

   ----------
   -- Dump --
   ----------

   procedure Dump
     (Direction : Net.Log.Data_Direction;
      Socket    : Net.Socket_Type'Class;
      Data      : Stream_Element_Array;
      Last      : Stream_Element_Offset)
   is
      use type Net.Log.Data_Direction;
   begin
      if Direction = Net.Log.Sent then
         Text_IO.Put_Line
           ("********** " & Net.Log.Data_Direction'Image (Direction));
         Text_IO.Put_Line
           (Translator.To_String (Data (Data'First .. Last)));
         Text_IO.New_Line;
      end if;
   end Dump;

   WS          : Server.HTTP;
   WC          : Client.HTTP_Connection;
   R           : Response.Data;
   Attachments : AWS.Attachments.List;

begin
   AWS.Attachments.Add
     (Attachments => Attachments,
      Filename    => "file1.dat",
      Headers     => AWS.Headers.Empty_List);
   AWS.Attachments.Add
     (Attachments => Attachments,
      Filename    => "file2.dat",
      Headers     => AWS.Headers.Empty_List);

   Server.Start
     (WS, "Post Attachments",
      CB'Unrestricted_Access,
      Port             => 0,
      Upload_Directory => ".");

   Text_IO.Put_Line ("started"); Ada.Text_IO.Flush;

   --  AWS.Net.Log.Start (Dump'Unrestricted_Access);

   Client.Create (WC, Server.Status.Local_URL (WS));

   Text_IO.New_Line;

   AWS.Client.Post (WC, R, URI => "/Upload", Data => "ID=100");

   Text_IO.New_Line;

   AWS.Client.Post
     (WC, R, URI => "/Upload", Data => "ID=101",
      Content_Type => AWS.MIME.Application_Form_Data,
      Attachments  => Attachments);

   Text_IO.New_Line;

   AWS.Client.Post
     (WC, R, URI => "/Upload?ID=102", Data => AWS.Client.No_Data,
      Content_Type => AWS.MIME.Application_Form_Data,
      Attachments  => Attachments);

   Text_IO.New_Line;

   AWS.Client.Post
     (WC, R, URI => "/Upload?ID=103", Data => "AnyOldString",
      Content_Type => AWS.Client.No_Data,
      Attachments  => Attachments);

   Text_IO.New_Line;

   AWS.Client.Post
     (WC, R, URI => "/Upload", Data => "ID=104",
      Content_Type => AWS.MIME.Application_Form_Data,
      Attachments  => Attachments);

   Client.Close (WC);
   Server.Shutdown (WS);
   Text_IO.Put_Line ("shutdown");
end Post_Attachments;
