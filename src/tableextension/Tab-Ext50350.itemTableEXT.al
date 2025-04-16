tableextension 50350 itemTableEXT extends Item
{
    fields
    {
        // Add changes to table fields here
        field(50900; "Comment Field"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}